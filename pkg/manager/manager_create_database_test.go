package manager

import "testing"

func TestShouldUseCreateDatabaseFileCopyStrategy(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name             string
		serverVersionNum int
		expected         bool
	}{
		{
			name:             "postgres14",
			serverVersionNum: 140012,
			expected:         false,
		},
		{
			name:             "postgres15",
			serverVersionNum: 150000,
			expected:         true,
		},
		{
			name:             "postgres16",
			serverVersionNum: 160001,
			expected:         true,
		},
	}

	for _, tt := range tests {
		tt := tt
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			got := shouldUseCreateDatabaseFileCopyStrategy(tt.serverVersionNum)
			if got != tt.expected {
				t.Fatalf("unexpected strategy decision for version %d: got %v, want %v", tt.serverVersionNum, got, tt.expected)
			}
		})
	}
}

func TestCreateDatabaseStatement(t *testing.T) {
	t.Parallel()

	t.Run("without strategy", func(t *testing.T) {
		t.Parallel()

		got := createDatabaseStatement("db-name", "owner-name", "template-name", false)
		want := `CREATE DATABASE "db-name" WITH OWNER "owner-name" TEMPLATE "template-name"`

		if got != want {
			t.Fatalf("unexpected create statement: got %q, want %q", got, want)
		}
	})

	t.Run("with strategy", func(t *testing.T) {
		t.Parallel()

		got := createDatabaseStatement("db-name", "owner-name", "template-name", true)
		want := `CREATE DATABASE "db-name" WITH OWNER "owner-name" TEMPLATE "template-name" STRATEGY=FILE_COPY`

		if got != want {
			t.Fatalf("unexpected create statement: got %q, want %q", got, want)
		}
	})
}
