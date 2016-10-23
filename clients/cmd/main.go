package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/nathanborror/pages/pages"
	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
)

var (
	token      = flag.String("token", "", "Authentication token")
	name       = flag.String("name", "", "Register name")
	email      = flag.String("email", "", "Register email")
	password   = flag.String("password", "", "Your password")
	identifier = flag.String("identifier", "", "Connect identifier")
	text       = flag.String("text", "", "Page text")
	id         = flag.String("id", "", "Page ID")
)

type client struct {
	accounts pages.AccountsClient
	pages    pages.PagesClient
}

// Accounts

func (c *client) register(ctx context.Context, name, email, password string) (*pages.Session, error) {
	register := &pages.RegisterRequest{Name: name, Email: email, Password: password}
	return c.accounts.Register(ctx, register)
}

func (c *client) connect(ctx context.Context, identifier, password string) (*pages.Session, error) {
	connect := &pages.ConnectRequest{Identifier: identifier, Password: password}
	return c.accounts.Connect(ctx, connect)
}

// Pages

func (c *client) pageCreate(ctx context.Context, text string) (*pages.Page, error) {
	newPage := &pages.PageCreateRequest{Text: text}
	return c.pages.PageCreate(ctx, newPage)
}

func (c *client) pageUpdate(ctx context.Context, id, text string) (*pages.Page, error) {
	updatePage := &pages.PageUpdateRequest{Id: id, Text: text}
	return c.pages.PageUpdate(ctx, updatePage)
}

func (c *client) pageGet(ctx context.Context, id string) (*pages.Page, error) {
	getPage := &pages.PageGetRequest{Id: id}
	return c.pages.PageGet(ctx, getPage)
}

func (c *client) pageList(ctx context.Context) (*pages.PagesSet, error) {
	return c.pages.PageList(ctx, &pages.Empty{})
}

func (c *client) pageDelete(ctx context.Context, id string) error {
	deletePage := &pages.PageDeleteRequest{Id: id}
	if _, err := c.pages.PageDelete(ctx, deletePage); err != nil {
		return err
	}
	return nil
}

// Auth

type auth struct {
	Token string
}

func (a *auth) GetRequestMetadata(ctx context.Context, uri ...string) (map[string]string, error) {
	return map[string]string{
		"token": a.Token,
	}, nil
}

func (a *auth) RequireTransportSecurity() bool {
	return false
}

// Main

func main() {
	flag.Parse()

	if len(os.Args) <= 1 {
		fmt.Println(`Page is a command for writing pages.

Usage:

  page command [arguments]

The commands are:

  register  create an account
  connect   log in to obtain an auth token
  list      show all pages
  get       show a specific page
  create    save a new page
  update    change a page
  delete    remove a page
`)
		os.Exit(0)
	}

	cmds := map[string]bool{
		"register": true,
		"connect":  true,
		"list":     true,
		"get":      true,
		"create":   true,
		"udpate":   true,
		"delete":   true,
	}
	if ok := cmds[os.Args[1]]; !ok {
		fmt.Printf("page: unknown subcommand '%s'\nRun 'page -help' for usage.\n", os.Args[1])
		os.Exit(0)
	}

	ctx := context.Background()

	// Credentials
	creds, err := credentials.NewClientTLSFromFile("dev.crt", "localhost")
	if err != nil {
		panic(err)
	}

	// Accounts connection
	aConn, err := grpc.Dial("localhost:8080",
		grpc.WithTransportCredentials(creds),
	)
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer aConn.Close()

	// Pages connection
	pConn, err := grpc.Dial("localhost:8080",
		grpc.WithTransportCredentials(creds),
		grpc.WithPerRPCCredentials(&auth{Token: *token}),
	)
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer pConn.Close()

	c := client{}
	c.accounts = pages.NewAccountsClient(aConn)
	c.pages = pages.NewPagesClient(pConn)

	// Execute command
	switch os.Args[1] {
	case "register":
		s, err := c.register(ctx, *name, *email, *password)
		if err != nil {
			panic(err)
		}
		fmt.Printf("Token: %s\n", s.Token)
	case "connect":
		s, err := c.connect(ctx, *identifier, *password)
		if err != nil {
			panic(err)
		}
		fmt.Printf("Token: %s\n", s.Token)
	case "list":
		set, err := c.pageList(ctx)
		if err != nil {
			panic(err)
		}
		for _, page := range set.Pages {
			fmt.Println(page.Text)
		}
	case "create":
		page, err := c.pageCreate(ctx, *text)
		if err != nil {
			panic(err)
		}
		fmt.Printf("Created page: %s\n", page.Text)
	default:
		os.Exit(0)
	}
}
