package main

import (
	"log"

	"github.com/nathanborror/pages/pages"
	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
)

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

func main() {

	ctx := context.Background()

	// Credentials
	creds, err := credentials.NewClientTLSFromFile("dev.crt", "localhost")
	if err != nil {
		panic(err)
	}

	// Accounts connection
	accountsConn, err := grpc.Dial("localhost:8080",
		grpc.WithTransportCredentials(creds),
	)
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}

	// Accounts client
	accountsClient := pages.NewAccountsClient(accountsConn)

	// Register
	register := &pages.RegisterRequest{Name: "Nathan", Email: "nathan@nthn.me", Password: "n"}
	session, err := accountsClient.Register(ctx, register)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("%#v\n", session)

	// Connect
	connect := &pages.ConnectRequest{Identifier: "nathan@nthn.me", Password: "n"}
	session, err = accountsClient.Connect(ctx, connect)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("%#v\n", session)

	// Close account connection
	accountsConn.Close()

	// Pages connection
	pagesConn, err := grpc.Dial("localhost:8080",
		grpc.WithTransportCredentials(creds),
		grpc.WithPerRPCCredentials(&auth{Token: session.Token}),
	)
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}

	// Pages client
	pagesClient := pages.NewPagesClient(pagesConn)

	// Create Page
	newPage := &pages.PageCreateRequest{Text: "First page!"}
	page, err := pagesClient.PageCreate(ctx, newPage)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("%#v\n", page)

	// Update Page
	updatePage := &pages.PageUpdateRequest{Id: page.Id, Text: "First page!"}
	page, err = pagesClient.PageUpdate(ctx, updatePage)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("%#v\n", page)

	// Get Page
	getPage := &pages.PageGetRequest{Id: page.Id}
	page, err = pagesClient.PageGet(ctx, getPage)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("%#v\n", page)

	// Get Pages
	list, err := pagesClient.PageList(ctx, &pages.Empty{})
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("%#v\n", list)

	// Delete Page
	deletePage := &pages.PageDeleteRequest{Id: page.Id}
	if _, err = pagesClient.PageDelete(ctx, deletePage); err != nil {
		log.Fatal(err)
	}
	log.Printf("%#v\n", deletePage)
}
