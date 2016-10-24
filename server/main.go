package main

import (
	"errors"
	"fmt"
	"net"
	"net/http"
	"strings"

	"golang.org/x/net/context"
	"golang.org/x/net/trace"

	"github.com/nathanborror/pages/pages"
	"github.com/nathanborror/pages/server/proxy"
	"github.com/nathanborror/pages/state"
	"github.com/nathanborror/pages/state/memory"
	"github.com/nathanborror/pages/state/sqlite"
	"github.com/nathanborror/pages/utils"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/metadata"
)

const ctxAccountAuthorizationID = "AccountAuthorizationID"

var (
	// ErrAccessDenied means the request was missing token meta-data.
	ErrAccessDenied = errors.New("Access denied")

	// ErrAccessDeniedMissingToken means the token meta-data value was empty.
	ErrAccessDeniedMissingToken = errors.New("Access denied: missing token")

	// ErrAccessDeniedInvalidToken means the provided token was invalid.
	ErrAccessDeniedInvalidToken = errors.New("Access denied: invalid token")
)

type server struct {
	state state.State
}

// Accounts Server

func (s *server) Register(ctx context.Context, in *pages.RegisterRequest) (*pages.Session, error) {
	account, err := s.state.AccountCreate(in.Name, in.Email, in.Password)
	if err != nil {
		return nil, err
	}
	token, err := s.state.AccountTokenSet(account.Id)
	if err != nil {
		return nil, err
	}
	session := &pages.Session{Account: account, Token: token}
	return session, nil
}

func (s *server) Connect(ctx context.Context, in *pages.ConnectRequest) (*pages.Session, error) {
	account, err := s.state.AccountForEmail(in.Identifier)
	if err != nil {
		return nil, err
	}
	if _, err = s.state.AccountForPassword(account.Id, in.Password); err != nil {
		return nil, err
	}
	token, err := s.state.AccountTokenSet(account.Id)
	if err != nil {
		return nil, err
	}
	session := &pages.Session{Account: account, Token: token}
	return session, nil
}

// Pages Server

func (s *server) PageCreate(ctx context.Context, in *pages.PageCreateRequest) (*pages.Page, error) {
	accountID := s.authorizedAccountID(ctx)
	return s.state.PageCreate(accountID, in.Text)
}

func (s *server) PageUpdate(ctx context.Context, in *pages.PageUpdateRequest) (*pages.Page, error) {
	accountID := s.authorizedAccountID(ctx)
	return s.state.PageUpdate(in.Id, accountID, in.Text)
}

func (s *server) PageDelete(ctx context.Context, in *pages.PageDeleteRequest) (*pages.Page, error) {
	accountID := s.authorizedAccountID(ctx)
	page, err := s.state.Page(in.Id)
	if err != nil {
		return nil, err
	}
	if err := s.state.PageDelete(in.Id, accountID); err != nil {
		return nil, err
	}
	return page, nil
}

func (s *server) PageGet(ctx context.Context, in *pages.PageGetRequest) (*pages.Page, error) {
	return s.state.Page(in.Id)
}

func (s *server) PageList(ctx context.Context, in *pages.Empty) (*pages.PagesSet, error) {
	recs, err := s.state.Pages()
	if err != nil {
		return nil, err
	}
	out := pages.PagesSet{
		Pages: recs,
		Total: int64(len(recs)),
		Page:  1,
	}
	return &out, nil
}

// Auth

func (s *server) authStreamInterceptor(srv interface{}, stream grpc.ServerStream, info *grpc.StreamServerInfo, handler grpc.StreamHandler) error {
	// TODO: Unclear how to pass new authenticated context into the stream handelr...
	if _, err := s.authorize(stream.Context()); err != nil {
		return err
	}
	return handler(srv, stream)
}

func (s *server) authUnaryInterceptor(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {
	public := map[string]bool{
		"/Accounts/Register": true,
		"/Accounts/Connect":  true,
		"/Pages/PageList":    true,
		"Pages/PageGet":      true,
	}
	if _, ok := public[info.FullMethod]; ok {
		return handler(ctx, req)
	}
	authedCtx, err := s.authorize(ctx)
	if err != nil {
		return nil, err
	}
	return handler(authedCtx, req)
}

func (s *server) authorize(ctx context.Context) (context.Context, error) {
	md, ok := metadata.FromContext(ctx)
	if !ok {
		return ctx, ErrAccessDenied
	}
	if len(md["token"]) == 0 {
		return ctx, ErrAccessDeniedMissingToken
	}
	token := strings.Join(md["token"], "")
	account, err := s.state.AccountForToken(token)
	if err != nil {
		return ctx, ErrAccessDeniedInvalidToken
	}
	return context.WithValue(ctx, ctxAccountAuthorizationID, account.Id), nil
}

func (s *server) authorizedAccountID(ctx context.Context) (id string) {
	value := ctx.Value(ctxAccountAuthorizationID)
	if value == nil {
		return
	}
	id = value.(string)
	return
}

func (s *server) authorizedAccount(ctx context.Context) (account *pages.Account) {
	id := s.authorizedAccountID(ctx)
	account, _ = s.state.Account(id)
	return
}

// Main

func main() {

	// Environment variables
	host := utils.GetenvString("SERVER_HOST", "localhost")
	port := utils.GetenvInt("SERVER_PORT", 8080)
	proxyPort := utils.GetenvInt("SERVER_PROXY_PORT", 8081)
	debug := utils.GetenvBool("DEBUG", true) // Runs on server host port 8082
	stateBackend := utils.GetenvString("SERVER_STATE", "memory")

	s := server{}

	// Initialize State
	state.Register("memory", memory.New)
	state.Register("sqlite", sqlite.New)
	s.state = state.New(stateBackend)

	// Credentials
	creds, err := credentials.NewServerTLSFromFile("dev.crt", "dev.key")
	if err != nil {
		panic(err)
	}

	// gRPC Server
	gs := grpc.NewServer(
		grpc.Creds(creds),
		grpc.StreamInterceptor(s.authStreamInterceptor),
		grpc.UnaryInterceptor(s.authUnaryInterceptor),
	)
	pages.RegisterAccountsServer(gs, &s)
	pages.RegisterPagesServer(gs, &s)

	// Listen over TCP
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", port))
	if err != nil {
		panic(err)
	}

	// Serve gRPC
	go gs.Serve(lis)

	// Serve debugger
	if debug {
		trace.DebugUseAfterFinish = true
		go http.ListenAndServe(":8082", nil)
	}

	// Serve gRPC gateway
	if err := proxy.Serve(fmt.Sprintf("%s:%d", host, port), proxyPort); err != nil {
		panic(err)
	}
}
