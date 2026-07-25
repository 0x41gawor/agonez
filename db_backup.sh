docker exec -e PGPASSWORD=$AGANDSKODE agonez-db pg_dump -U $NOME -d agonez_db -F p > agonez_db_backup_$(date +%F).sql
