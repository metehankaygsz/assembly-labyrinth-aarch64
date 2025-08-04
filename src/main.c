// Minimal SDL front-end: C handles window/render + input, assembly owns game state.

#include <SDL.h>
#include <stdio.h>

// Assembly API (implemented in game.S)
void game_init(void);
void game_reset_level(int level);
int  game_update(int dir);        // 0=up, 1=right, 2=down, 3=left; returns 1 when goal reached
void game_get_player(int *x, int *y);
int  game_get_tile(int index);
int  game_get_level(void);

// Grid/viewport configuration
#define GRID_W 20
#define GRID_H 15
#define TILE   32
#define WIN_W (GRID_W * TILE)
#define WIN_H (GRID_H * TILE)
#define TOTAL_LEVELS 10

// Solid color rectangle helper
static void fill(SDL_Renderer* r, int x,int y,int w,int h,int R,int G,int B){
    SDL_Rect rc = (SDL_Rect){x,y,w,h};
    SDL_SetRenderDrawColor(r,R,G,B,255);
    SDL_RenderFillRect(r,&rc);
}

// Draw current level tiles + player
static void render(SDL_Renderer* r){
    SDL_SetRenderDrawColor(r,18,18,18,255);
    SDL_RenderClear(r);

    for(int j=0;j<GRID_H;++j){
        for(int i=0;i<GRID_W;++i){
            int t = game_get_tile(j*GRID_W + i);
            if(t==1)      fill(r, i*TILE, j*TILE, TILE, TILE, 60,60,60);    // wall
            else if(t==2) fill(r, i*TILE, j*TILE, TILE, TILE, 0,140,0);     // goal
            else if(t==3) fill(r, i*TILE, j*TILE, TILE, TILE, 40,40,100);   // start
        }
    }

    int px=0, py=0;
    game_get_player(&px,&py);
    fill(r, px*TILE+4, py*TILE+4, TILE-8, TILE-8, 220,200,40);               // player

    SDL_RenderPresent(r);
}

int main(void){
    // Pixel-perfect scaling on macOS/HiDPI
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "0");
    SDL_SetHint(SDL_HINT_VIDEO_HIGHDPI_DISABLED, "1");

    if(SDL_Init(SDL_INIT_VIDEO|SDL_INIT_EVENTS)!=0){
        fprintf(stderr,"SDL_Init error: %s\n", SDL_GetError());
        return 1;
    }

    SDL_Window* win = SDL_CreateWindow(
        "Assembly Labyrinth",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        WIN_W, WIN_H,
        SDL_WINDOW_SHOWN
    );
    if(!win){ fprintf(stderr,"SDL_CreateWindow error: %s\n", SDL_GetError()); SDL_Quit(); return 1; }

    SDL_Renderer* ren = SDL_CreateRenderer(
        win, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC
    );
    if(!ren) ren = SDL_CreateRenderer(win,-1, SDL_RENDERER_SOFTWARE);
    if(!ren){ fprintf(stderr,"SDL_CreateRenderer error: %s\n", SDL_GetError()); SDL_DestroyWindow(win); SDL_Quit(); return 1; }

    SDL_RenderSetLogicalSize(ren, WIN_W, WIN_H);
    SDL_RenderSetIntegerScale(ren, SDL_TRUE);

    // Boot game state
    game_init();
    game_reset_level(0);

    // Quick ABI sanity: first six tiles of the level
    for(int i=0;i<6;i++) printf("tile[%d]=%d\n", i, game_get_tile(i));

    int running = 1;
    while (running) {
        // Keep the frame fresh and update window title
        render(ren);
        char title[64];
        snprintf(title, sizeof(title), "Assembly Labyrinth — Level %d", game_get_level());
        SDL_SetWindowTitle(win, title);

        SDL_Event e;
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT) running = 0;

            if (e.type == SDL_KEYDOWN) {
                // Ignore held-key repeats to avoid multiple moves per press
                if (e.key.repeat) continue;

                SDL_Keycode k = e.key.keysym.sym;
                if (k == SDLK_ESCAPE) { running = 0; break; }
                if (k == SDLK_r) { game_reset_level(game_get_level()); break; }

                // Map keys to 4 directions
                int dir = -1;
                if (k == SDLK_UP    || k == SDLK_w || k == SDLK_i) dir = 0;
                if (k == SDLK_RIGHT || k == SDLK_d || k == SDLK_l) dir = 1;
                if (k == SDLK_DOWN  || k == SDLK_s || k == SDLK_k) dir = 2;
                if (k == SDLK_LEFT  || k == SDLK_a || k == SDLK_j) dir = 3;

                if (dir != -1) {
                    // Optional debug: peek next tile before moving
                    int px, py; game_get_player(&px, &py);
                    int nx=px, ny=py;
                    if (dir==0) ny--; else if (dir==1) nx++; else if (dir==2) ny++; else if (dir==3) nx--;
                    int idx = ny*GRID_W + nx;
                    int t = (nx>=0 && nx<GRID_W && ny>=0 && ny<GRID_H) ? game_get_tile(idx) : -1;
                    printf("KEYDOWN dir=%d  before=(%d,%d)  move_to=(%d,%d) tile=%d\n",
                           dir, px, py, nx, ny, t);
                    fflush(stdout);

                    // Let assembly update player and report completion
                    int completed = game_update(dir);

                    game_get_player(&px, &py);
                    printf("after=(%d,%d) completed=%d  level=%d\n", px, py, completed, game_get_level());
                    fflush(stdout);

                    // Advance level on success; wrap after the last one
                    if (completed > 0) {
                        int cur  = game_get_level();
                        int next = (cur + 1) % TOTAL_LEVELS;

                        SDL_FlushEvent(SDL_KEYDOWN);   // prevent double-advance from buffered events
                        game_reset_level(next);

                        int spx, spy; game_get_player(&spx, &spy);
                        printf("Advanced to level=%d  start=(%d,%d)\n", game_get_level(), spx, spy);
                        render(ren);
                        SDL_Delay(60);                  // small visual pause
                    }
                }
            }
        }

        SDL_Delay(1); // yield a bit
    }

    SDL_DestroyRenderer(ren);
    SDL_DestroyWindow(win);
    SDL_Quit();
    return 0;
}