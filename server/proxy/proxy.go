package proxy

import (
	"fmt"
	"net/http"

	"golang.org/x/net/context"

	"github.com/grpc-ecosystem/grpc-gateway/runtime"
	"github.com/nathanborror/pages/pages"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
)

// allowCORS allows Cross Origin Resoruce Sharing from any origin.
// Don't do this without consideration in production systems.
func allowCORS(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if origin := r.Header.Get("Origin"); origin != "" {
			w.Header().Set("Access-Control-Allow-Origin", origin)
			if r.Method == "OPTIONS" && r.Header.Get("Access-Control-Request-Method") != "" {
				preflightHandler(w, r)
				return
			}
		}
		h.ServeHTTP(w, r)
	})
}

func preflightHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Accept, Grpc-Metadata-token")
	w.Header().Set("Access-Control-Allow-Methods", "GET, HEAD, POST, PUT, DELETE")
	return
}

// Serve starts the gateway
func Serve(endpoint string, port int) error {
	ctx := context.Background()
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	// Credentials
	creds, err := credentials.NewClientTLSFromFile("dev.crt", "localhost")
	if err != nil {
		panic(err)
	}

	opts := []grpc.DialOption{grpc.WithTransportCredentials(creds)}
	mux := runtime.NewServeMux()

	if err := pages.RegisterAccountsHandlerFromEndpoint(ctx, mux, endpoint, opts); err != nil {
		return err
	}
	if err := pages.RegisterPagesHandlerFromEndpoint(ctx, mux, endpoint, opts); err != nil {
		return err
	}

	return http.ListenAndServe(fmt.Sprintf(":%d", port), allowCORS(mux))
}
