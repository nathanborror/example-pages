package utils

import (
	"crypto/sha1"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/base64"
	"fmt"
	"io"
	"math/rand"
	"strconv"
	"strings"
	"time"

	"golang.org/x/crypto/pbkdf2"
)

// RandSha1 returns a SHA1 hash based on the current UNIX timestamp
// and a random number between 0 and 1000 in an attempt to be random.
func RandSha1() string {
	salt := RandString(12)
	time := strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
	return Sha1(time + salt)
}

// Sha1 returns a SHA1 hash based on the given value.
func Sha1(values ...string) string {
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

// PasswordMake returns an encrypted password string using pbkdf2_sha256
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
	if len(parts) < 3 {
		return false
	}
	algorithm := parts[0]
	iterations, _ := strconv.Atoi(parts[1])
	salt := parts[2]
	encodedAttempt := PasswordEncode(algorithm, iterations, salt, attempt)
	return subtle.ConstantTimeCompare([]byte(password), []byte(encodedAttempt)) == 1
}
