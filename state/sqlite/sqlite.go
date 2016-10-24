package sqlite

import (
	"database/sql"
	"fmt"
	"log"
	"strings"
	"time"

	"github.com/nathanborror/pages/pages"
	"github.com/nathanborror/pages/state"
	"github.com/nathanborror/pages/utils"

	_ "github.com/mattn/go-sqlite3" // sqlite driver
)

type sqlite struct {
	db *sql.DB
}

// New returns a Sqlite backed state interface.
func New() state.State {

	filename := utils.GetenvString("SQLITE_FILENAME", "/tmp/db.sqlite")

	db, err := sql.Open("sqlite3", filename)
	if err != nil {
		log.Fatalf("sqlite.New: %s", err.Error())
	}

	tables := `
		CREATE TABLE IF NOT EXISTS account (
			id TEXT PRIMARY KEY,
			name TEXT NOT NULL default '',
			email TEXT NOT NULL UNIQUE,
			password TEXT NOT NULL,
			token TEXT NOT NULL default '',
			created sqlite3_int64,
			modified sqlite3_int64
		);
		CREATE TABLE IF NOT EXISTS page (
			id TEXT PRIMARY KEY,
			account TEXT NOT NULL default '',
			text TEXT NOT NULL default '',
			created sqlite3_int64,
			modified sqlite3_int64
		)`
	if _, err := db.Exec(tables); err != nil {
		log.Fatalln("sqlite.New: Error creating tables: %s", err)
	}

	return &sqlite{db: db}
}

// Description returns a human readable string identifying the Storage backend in use.
func (s *sqlite) Description() string {
	return "sqlite"
}

// Account returns an account for a given id.
func (s *sqlite) Account(id string) (*pages.Account, error) {
	var rec pages.Account
	stmt, err := s.db.Prepare("SELECT id,name,email,created,modified FROM account WHERE id = ?")
	if err != nil {
		return nil, err
	}
	row := stmt.QueryRow(id)
	if err := scanAccount(row, &rec); err != nil {
		return nil, state.ErrAccountNotFound
	}
	return &rec, nil
}

// AccountForEmail returns an account for a given email address.
func (s *sqlite) AccountForEmail(email string) (*pages.Account, error) {
	var rec pages.Account
	stmt, err := s.db.Prepare("SELECT id,name,email,created,modified FROM account WHERE email = ?")
	if err != nil {
		return nil, err
	}
	row := stmt.QueryRow(email)
	if err := scanAccount(row, &rec); err != nil {
		return nil, state.ErrAccountNotFound
	}
	return &rec, nil
}

// AccountForToken returns an account for a given token.
func (s *sqlite) AccountForToken(token string) (*pages.Account, error) {
	var rec pages.Account
	stmt, err := s.db.Prepare("SELECT id,name,email,created,modified FROM account WHERE token = ?")
	if err != nil {
		return nil, err
	}
	row := stmt.QueryRow(token)
	if err := scanAccount(row, &rec); err != nil {
		return nil, state.ErrAccountNotFound
	}
	return &rec, nil
}

func (s *sqlite) AccountForPassword(id, passwordAttempt string) (*pages.Account, error) {
	var password string
	stmt, err := s.db.Prepare("SELECT password FROM account WHERE id = ?")
	if err != nil {
		return nil, err
	}
	if err = stmt.QueryRow(id).Scan(&password); err == sql.ErrNoRows {
		return nil, state.ErrAccountNotFound
	} else if err != nil {
		return nil, err
	}
	if !utils.IsPasswordValid(password, passwordAttempt) {
		return nil, state.ErrPasswordInvalid
	}
	return s.Account(id)
}

// AccountCreate creates and returns a new account.
func (s *sqlite) AccountCreate(name, email, password string) (*pages.Account, error) {
	ts := now()
	id := uniqueID()
	stmt, err := s.db.Prepare("INSERT INTO account (id,name,email,password,created,modified) VALUES (?,?,?,?,?,?)")
	if err != nil {
		return nil, err
	}
	if _, err := stmt.Exec(id, name, email, utils.PasswordMake(password), ts, ts); err != nil {
		return nil, err
	}
	return s.Account(id)
}

// AccountTokenSet sets an account's access token.
func (s *sqlite) AccountTokenSet(id string) (string, error) {
	ts := now()
	token := utils.RandSha1()
	stmt, err := s.db.Prepare("UPDATE account SET token = ?, modified = ? WHERE id = ?")
	if err != nil {
		return "", err
	}
	if _, err := stmt.Exec(token, ts, id); err != nil {
		return "", err
	}
	return token, nil
}

// Pages returns all pages.
func (s *sqlite) Pages() ([]*pages.Page, error) {
	var (
		recs       []*pages.Page
		accountIDs []string
	)
	pageAccountMap := make(map[string]string)

	// Fetch pages
	stmt, err := s.db.Prepare("SELECT id,account,text,created,modified FROM page")
	if err != nil {
		return nil, err
	}
	rows, err := stmt.Query()
	defer rows.Close()
	for rows.Next() {
		var (
			rec       pages.Page
			accountID string
		)
		if err = rows.Scan(&rec.Id, &accountID, &rec.Text, &rec.Created, &rec.Modified); err != nil {
			return nil, err
		}
		pageAccountMap[rec.Id] = accountID
		recs = append(recs, &rec)
	}
	if len(recs) == 0 {
		return recs, nil
	}

	// Fetch accounts and apply them to page results
	for _, id := range pageAccountMap {
		accountIDs = append(accountIDs, fmt.Sprintf("'%s'", id))
	}
	accounts, err := s.accountsIn(accountIDs)
	if err != nil {
		return nil, err
	}
	for _, rec := range recs {
		accountID := pageAccountMap[rec.Id]
		account := accounts[accountID]
		rec.Account = &account
	}
	return recs, nil
}

// Page returns an page for a given id.
func (s *sqlite) Page(id string) (*pages.Page, error) {
	var (
		rec     pages.Page
		account pages.Account
	)
	stmt, err := s.db.Prepare("SELECT id,account,text,created,modified FROM page WHERE id = ?")
	if err != nil {
		return nil, err
	}
	row := stmt.QueryRow(id)
	if err = scanPage(row, &rec, &account); err != nil {
		return nil, state.ErrPageNotFound
	}
	if account.Id == "" {
		return nil, fmt.Errorf("Could not retrieve account ID")
	}
	rec.Account, err = s.Account(account.Id)
	if err != nil {
		return nil, fmt.Errorf("Could not retrieve page for ID '%s' (%s)", id, err)
	}
	return &rec, nil
}

// PageCreate creates and returns a new page.
func (s *sqlite) PageCreate(accountID, text string) (*pages.Page, error) {
	ts := now()
	id := uniqueID()
	stmt, err := s.db.Prepare("INSERT INTO page (id,account,text,created,modified) VALUES (?,?,?,?,?)")
	if err != nil {
		return nil, err
	}
	if _, err := stmt.Exec(id, accountID, text, ts, ts); err != nil {
		return nil, err
	}
	return s.Page(id)
}

// PageUpdate updates and returns the updated page.
func (s *sqlite) PageUpdate(id, account, text string) (*pages.Page, error) {
	ts := now()
	stmt, err := s.db.Prepare("UPDATE page SET account = ?, text = ?, modified = ? WHERE id = ?")
	if err != nil {
		return nil, err
	}
	if _, err := stmt.Exec(account, text, ts, id); err != nil {
		return nil, err
	}
	return s.Page(id)
}

// PageDelete deletes an page for a given id.
func (s *sqlite) PageDelete(id, account string) error {
	stmt, err := s.db.Prepare("DELETE FROM page WHERE id = ? AND account = ?")
	if err != nil {
		return err
	}
	if _, err := stmt.Exec(id, account); err != nil {
		return err
	}
	return nil
}

// Helpers

func uniqueID() string {
	return utils.RandSha1()
}

func now() int64 {
	return time.Now().UTC().UnixNano()
}

func scanAccount(row *sql.Row, rec *pages.Account) error {
	err := row.Scan(&rec.Id, &rec.Name, &rec.Email, &rec.Created, &rec.Modified)
	if err == sql.ErrNoRows {
		return fmt.Errorf("Not found")
	} else if err != nil {
		return err
	}
	return nil
}

func scanPage(row *sql.Row, rec *pages.Page, account *pages.Account) error {
	err := row.Scan(&rec.Id, &account.Id, &rec.Text, &rec.Created, &rec.Modified)
	if err == sql.ErrNoRows {
		return fmt.Errorf("Account not found")
	} else if err != nil {
		return err
	}
	return nil
}

func (s *sqlite) accountsIn(ids []string) (map[string]pages.Account, error) {
	accounts := make(map[string]pages.Account)
	stmt, err := s.db.Prepare("SELECT id,name,email,created,modified FROM account WHERE id IN (" + strings.Join(ids, ",") + ")")
	if err != nil {
		return nil, err
	}
	rows, err := stmt.Query()
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		rec := pages.Account{}
		if err := rows.Scan(&rec.Id, &rec.Name, &rec.Email, &rec.Created, &rec.Modified); err != nil {
			return nil, err
		}
		accounts[rec.Id] = rec
	}
	return accounts, nil
}
