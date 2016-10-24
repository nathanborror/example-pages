package state

import (
	"errors"
	"fmt"

	"github.com/nathanborror/pages/pages"
)

var (
	// ErrAccountNotFound means the account wasn't found for the given identifier.
	ErrAccountNotFound = errors.New("Account not found")

	// ErrPageNotFound means the page wasn't found for the given identifier.
	ErrPageNotFound = errors.New("Page not found")

	// ErrPageUnauthorized means the page does not belong to the account.
	ErrPageUnauthorized = errors.New("Page does not belong to account")
)

// State represents an interface for interacting with package types.
type State interface {

	// Accounts
	Account(id string) (*pages.Account, error)
	AccountForEmail(email string) (*pages.Account, error)
	AccountForToken(token string) (*pages.Account, error)
	AccountForPassword(id, password string) (*pages.Account, error)
	AccountTokenSet(id, token string) error
	AccountCreate(name, email, password string) (*pages.Account, error)

	// Pages
	Pages() ([]*pages.Page, error)
	Page(id string) (*pages.Page, error)
	PageCreate(account, text string) (*pages.Page, error)
	PageUpdate(id, account, text string) (*pages.Page, error)
	PageDelete(id, account string) error

	Description() string
}

// Backend represents a state backend that can be instantiated.
type Backend func() State

// Register adds a potential backed to the registry.
func Register(kind string, backend Backend) {
	registered[kind] = backend
}

// New instantiates a state backend.
func New(kind string) State {
	maker, ok := registered[kind]
	if !ok {
		fmt.Printf("state: state backend '%s' was not registered\n", kind)
		return nil
	}
	return maker()
}

var registered = make(map[string]Backend)
