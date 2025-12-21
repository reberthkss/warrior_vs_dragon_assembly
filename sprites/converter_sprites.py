import sys
from PIL import Image

# --- CONFIGURAÇÃO DE TAMANHOS ---
# Lista de ativos: (Nome do Arquivo, Nome do Label, Largura Desejada)
ASSETS = [
    # WARRIOR SPRITES
    # ("warrior.png", "sprite_player", 48),   
    # ("warrior_defeated.png", "sprite_player_defeated", 48),   
    # ("warrior_spear.png",    "warrior_spear", 48),   
    # ("spear.png",    "spear", 48),   
    # ("sprite_warrior_shield.png", "warrior_shield", 48),   
    # ("warrior_launching_net.png", "sprite_warrior_launching_net", 54),   
    
    # DRAGON SRPITEES
    # ("dragon.png",    "sprite_dragon", 110)   
    # ("dragon_defeated.png",    "sprite_dragon_defeated", 110),   
    # ("dragon_fireball.png",    "sprite_dragon_fireball", 48),   
    # ("fireball.png",    "fireball", 48),   
    # ("sprite_dragon_preparing_inferno.png",    "sprite_dragon_preparing_inferno", 48),   
    # ("dragon_defense.png",    "sprite_dragon_defense", 48),   
    ("dragon_on_net.png",    "sprite_dragon_on_net", 48),   


]
# --------------------------------

def hex_color(r, g, b, a):
    if a < 128: return "0" # Transparente
    return f"0x{r:02X}{g:02X}{b:02X}"

def converter_tudo():
    print("# --- ARQUIVO DE SPRITES GERADO ---")
    
    for arquivo, label, largura_final in ASSETS:
        try:
            img = Image.open(arquivo).convert("RGBA")
            
            # Calcula altura proporcional
            w_percent = (largura_final / float(img.size[0]))
            h_size = int((float(img.size[1]) * float(w_percent)))
            img = img.resize((largura_final, h_size), Image.Resampling.NEAREST)
            
            width, height = img.size
            pixels = list(img.getdata())
            
            print(f"\n{label}:")
            print(f"    .word {width}, {height}  # Dimensoes ({width}x{height})")
            print(f"    .word ", end="")
            
            buffer = []
            for p in pixels:
                buffer.append(hex_color(*p))
                if len(buffer) >= 8: # Quebra linha a cada 8 pixels
                    print(", ".join(buffer))
                    print("    .word ", end="")
                    buffer = []
            
            if buffer:
                print(", ".join(buffer))
                
        except FileNotFoundError:
            print(f"\n# ERRO: Arquivo '{arquivo}' nao encontrado!")
        except Exception as e:
            print(f"\n# ERRO em {arquivo}: {e}")

if __name__ == "__main__":
    converter_tudo()