all: setup-marketplace create-drop setup-bidders bid settle check

webpage: setup-marketplace create-drop 

.PHONY: setup-marketplace
setup-marketplace:
	go run ./examples/setup_marketplace/main.go

.PHONY: create-drop
create-drop:
	go run ./examples/create_drop/main.go

.PHONY: setup-bidders
setup-bidders:
	go run ./examples/setup_bidders/main.go

.PHONY: bid
bid:
	go run ./examples/bid/main.go

.PHONY: settle
settle:
	go run ./examples/settle/main.go

.PHONY: check
check:
	go run ./examples/check/main.go

.PHONY: tick
tick:
	go run ./examples/tick/main.go
