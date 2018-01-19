#!/bin/bash
set -e
APPLICATION_USER="circle"
DEFAULT_DATABASE="circle"
DATABASES=(${databases})

main() {
	pull_postgres
	create_user "$${APPLICATION_USER}"
	for db in "$${DATABASES[@]}"; do
		create_db $db
	done
}

psql() {
	local POSTGRES_HOST="${postgres_host}"
	local POSTGRES_USERNAME="${postgres_username}"
	local POSTGRES_PASSWORD="${postgres_password}"
	local POSTGRES_VERSION="${postgres_version}"
	docker run -it --rm -e PGPASSWORD="$${POSTGRES_PASSWORD}" postgres:9.5.5 \
		psql -h $${POSTGRES_HOST} -U $${POSTGRES_USERNAME} -d circle -c "$$@"
}

pull_postgres() {
	docker pull postgres:9.5.5
}

create_user() {
	psql "CREATE USER $${1} WITH PASSWORD '${application_password}'"
	psql "grant all privileges on database $${DEFAULT_DATABASE} to $${APPLICATION_USER}"
}

create_db() {
	local DB="$$@"
	echo "Creating DB $${DB}"
	if ! `psql "SELECT 1 FROM pg_database WHERE datname = '$${DB}'" | grep -q 1`; then
	  psql "create database $${DB}"
	  psql "grant all privileges on database $${DB} to $${APPLICATION_USER}"
	else
	  echo "DB already exists"
	fi
}

main
