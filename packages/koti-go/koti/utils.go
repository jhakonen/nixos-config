package koti

func Filter[T any](list []T, fn func(T) bool) []T {
	values := []T{}
	for _, value := range list {
		if fn(value) {
			values = append(values, value)
		}
	}
	return values
}

func Map[T any, E any](list []T, fn func(T) E) []E {
	values := []E{}
	for _, value := range list {
		values = append(values, fn(value))
	}
	return values
}
