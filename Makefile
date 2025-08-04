APP      = labyrinth
SRC_DIR  = src
OBJS     = $(SRC_DIR)/main.o $(SRC_DIR)/game.o

CFLAGS   = -O2 -std=c11 -Wall -Wextra -Wno-deprecated-declarations \
           -I/opt/homebrew/include -I/opt/homebrew/include/SDL2 -D_THREAD_SAFE
LDFLAGS  = -L/opt/homebrew/lib -lSDL2 -framework ApplicationServices

$(APP): $(OBJS)
	clang -o $@ $(OBJS) $(LDFLAGS)

$(SRC_DIR)/main.o: $(SRC_DIR)/main.c
	clang $(CFLAGS) -c $< -o $@

$(SRC_DIR)/game.o: $(SRC_DIR)/game.S $(SRC_DIR)/levels.inc
	clang -c $< -o $@

clean:
	rm -f $(SRC_DIR)/*.o $(APP)