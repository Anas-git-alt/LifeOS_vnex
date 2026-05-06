.PHONY: doctor up down api web smoke compile

doctor:
	python3 scripts/doctor.py

up:
	docker compose up --build

down:
	docker compose down

api:
	uvicorn lifeos_api.main:app --reload --app-dir apps/api

web:
	npm --prefix apps/web run dev

smoke:
	python3 scripts/smoke_test.py

compile:
	python3 -m compileall apps packages scripts
