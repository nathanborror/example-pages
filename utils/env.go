package utils

import (
	"strconv"
	"syscall"
)

// GetenvString retrieves the string value of the environment variable named by
// the key. It returns the string, which will be set to the fallback if the
// variable is not present.
func GetenvString(key, fallback string) string {
	if v, ok := syscall.Getenv(key); ok {
		return v
	}
	return fallback
}

// GetenvBool retrieves the boolean value of the environment variable named by
// the key. It returns true or false, which will be set to the fallback if the
// variable is not present.
func GetenvBool(key string, fallback bool) bool {
	if v, ok := syscall.Getenv(key); ok {
		b, err := strconv.ParseBool(v)
		if err != nil {
			return fallback
		}
		return b
	}
	return fallback
}

// GetenvInt retrieves the integer value of the environment variable named by
// the key. It returns the integer, which will be set to the fallback if the
// variable is not present.
func GetenvInt(key string, fallback int) int {
	if v, ok := syscall.Getenv(key); ok {
		b, err := strconv.Atoi(v)
		if err != nil {
			return fallback
		}
		return b
	}
	return fallback
}
