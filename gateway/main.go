package main

import (
	"flag"
	"fmt"
	"net/http"

	"golang.org/x/net/context"

	"github.com/golang/glog"
	"github.com/grpc-ecosystem/grpc-gateway/runtime"
	"github.com/nathanborror/pages/pages"
	"google.golang.org/grpc"
)

var (
	host = flag.String("host", "localhost", "Host of service")
	port = flag.Int("port", 8080, "Port of service")
)

func run() error {

	ctx := context.Background()
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	mux := runtime.NewServeMux()
	opts := []grpc.DialOption{grpc.WithInsecure()}
	err := pages.RegisterAccountsHandlerFromEndpoint(ctx, mux, fmt.Sprintf("%s:%d", *host, *port), opts)
	if err != nil {
		return err
	}

	http.ListenAndServe(fmt.Sprintf(":%d", *port), mux)
	return nil
}

func main() {
	flag.Parse()
	defer glog.Flush()

	if err := run(); err != nil {
		glog.Fatal(err)
	}
}
