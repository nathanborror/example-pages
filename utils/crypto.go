package utils

import (
	"crypto/hmac"
	"crypto/sha1"
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	"io"
	"math/rand"
	"strconv"
	"strings"
	"time"

	"golang.org/x/crypto/pbkdf2"
)

// RandomHash returns a SHA1 hash based on the current UNIX timestamp
// and a random number between 0 and 1000 in an attempt to be random.
func RandomHash() string {
	salt := RandString(12)
	time := strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
	return Hash(time + salt)
}

// Hash returns a SHA1 hash based on the given value.
func Hash(values ...string) string {
	hasher := sha1.New()
	str := strings.Join(values, "")
	io.WriteString(hasher, str)
	return fmt.Sprintf("%x", hasher.Sum(nil))
}

// RandString returns a random string of a given length.
func RandString(length int) string {
	letters := []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
	b := make([]rune, length)
	for i := range b {
		b[i] = letters[rand.Intn(len(letters))]
	}
	return string(b)
}

// Sha256Hash returns an Sha256 HMAC
func Sha256Hash(secret string, message string) string {
	key := []byte(secret)
	h := hmac.New(sha256.New, key)
	h.Write([]byte(message))
	return base64.StdEncoding.EncodeToString(h.Sum(nil))
}

// PasswordMake returns an encrypted password string using `pbkdf2_sha256`
// algorithm.
func PasswordMake(password string) string {
	algorithm := "pbkdf2_sha256"
	iterations := 12000
	salt := RandString(12)
	return PasswordEncode(algorithm, iterations, salt, password)
}

// PasswordEncode encrypts a given password and returns a string of information
// used to encrypt password attempts. Pieces are seperated by '$' and include:
// <Algorithm>$<iterations>$<salt>$<encoded password>
func PasswordEncode(algorithm string, iterations int, salt string, password string) string {
	hash := pbkdf2.Key([]byte(password), []byte(salt), iterations, sha256.Size, sha256.New)
	return fmt.Sprintf("%s$%d$%s$%s", algorithm, iterations, salt, base64.StdEncoding.EncodeToString(hash))
}

// IsPasswordValid checks whether a password attempt is valid against an
// existing encrypted password.
func IsPasswordValid(password string, attempt string) bool {
	parts := strings.Split(password, "$")
	algorithm := parts[0]
	iterations, _ := strconv.Atoi(parts[1])
	salt := parts[2]
	return password == PasswordEncode(algorithm, iterations, salt, attempt)
}
