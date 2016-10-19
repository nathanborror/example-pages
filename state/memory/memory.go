package memory

import (
	"time"

	"github.com/nathanborror/pages/pages"
	"github.com/nathanborror/pages/state"
	"github.com/nathanborror/pages/utils"
)

type memory struct {
	accounts  map[string]*pages.Account
	tokens    map[string]string
	passwords map[string]string
	pages     map[string]*pages.Page
}

// New returns a memory state based on the provided config.
func New(config map[string]string) state.State {
	return &memory{
		make(map[string]*pages.Account),
		make(map[string]string),
		make(map[string]string),
		make(map[string]*pages.Page),
	}
}

// Description returns a human readable string identifying the Storage backend in use.
func (s *memory) Description() string {
	return "memmory"
}

// Account returns an account for a given id.
func (s *memory) Account(id string) (*pages.Account, error) {
	rec, ok := s.accounts[id]
	if !ok {
		return nil, state.ErrAccountNotFound
	}
	return rec, nil
}

// AccountForEmail returns an account for a given email address.
func (s *memory) AccountForEmail(email string) (*pages.Account, error) {
	for _, rec := range s.accounts {
		if rec.Email == email {
			return s.Account(rec.Id)
		}
	}
	return nil, state.ErrAccountNotFound
}

// AccountForToken returns an account for a given token.
func (s *memory) AccountForToken(token string) (*pages.Account, error) {
	if id, ok := s.tokens[token]; ok {
		return s.Account(id)
	}
	return nil, state.ErrAccountNotFound
}

func (s *memory) AccountForPassword(id, attempt string) (*pages.Account, error) {
	if password, ok := s.passwords[id]; ok {
		if utils.IsPasswordValid(password, attempt) {
			return s.Account(id)
		}
	}
	return nil, state.ErrAccountNotFound
}

// AccountCreate creates and returns a new account.
func (s *memory) AccountCreate(name, email, password string) (*pages.Account, error) {
	ts := now()
	rec := pages.Account{
		Name:     name,
		Email:    email,
		Created:  ts,
		Modified: ts,
		Id:       uniqueID(),
	}
	s.accounts[rec.Id] = &rec
	s.passwords[rec.Id] = password
	return &rec, nil
}

// AccountTokenSet sets an account's access token.
func (s *memory) AccountTokenSet(id, token string) error {
	rec, ok := s.accounts[id]
	if !ok {
		return state.ErrAccountNotFound
	}
	s.tokens[token] = rec.Id
	return nil
}

// Pages returns all pages.
func (s *memory) Pages() ([]*pages.Page, error) {
	out := []*pages.Page{}
	for _, rec := range s.pages {
		out = append(out, rec)
	}
	return out, nil
}

// Page returns an page for a given id.
func (s *memory) Page(id string) (*pages.Page, error) {
	rec, ok := s.pages[id]
	if !ok {
		return nil, state.ErrPageNotFound
	}
	return rec, nil
}

// PageCreate creates and returns a new page.
func (s *memory) PageCreate(accountID, text string) (*pages.Page, error) {
	ts := now()
	account := s.accounts[accountID]
	page := pages.Page{
		Account:  account,
		Text:     text,
		Created:  ts,
		Modified: ts,
		Id:       uniqueID(),
	}
	s.pages[page.Id] = &page
	return s.Page(page.Id)
}

// PageUpdate updates and returns the updated page.
func (s *memory) PageUpdate(id, account, text string) (*pages.Page, error) {
	rec, ok := s.pages[id]
	if !ok {
		return nil, state.ErrPageNotFound
	}
	if rec.Account.Id != account {
		return nil, state.ErrPageUnauthorized
	}
	rec.Text = text
	rec.Modified = now()
	s.pages[rec.Id] = rec
	return s.Page(rec.Id)
}

// PageDelete deletes an page for a given id.
func (s *memory) PageDelete(id, account string) error {
	rec, ok := s.pages[id]
	if !ok {
		return state.ErrPageNotFound
	}
	if rec.Account.Id != account {
		return state.ErrPageUnauthorized
	}
	delete(s.pages, id)
	return nil
}

// Helpers

func uniqueID() string {
	return utils.RandomHash()
}

func now() int64 {
	return time.Now().UTC().UnixNano()
}
