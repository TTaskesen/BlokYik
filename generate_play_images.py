#!/usr/bin/env python3
"""
Generate 8 Google Play store screenshots for Blok Yık game.
Size: 1080x1920 (9:16) - phone screenshots.
"""
from PIL import Image, ImageDraw, ImageFont
import os

OUTPUT_DIR = "/Users/turguttaskesen/GodotProjects/BlokYik/google_play_assets"
WIDTH, HEIGHT = 1080, 1920

os.makedirs(OUTPUT_DIR, exist_ok=True)

# Colors based on project.godot and scenes
BG_COLOR = (4, 5, 9)            # 0.04,0.05,0.09
PANEL_COLOR = (8, 11, 18)       # 0.08,0.11,0.18
ACCENT_RED = (241, 55, 77)      # ~0.95,0.22,0.3
TEXT_WHITE = (255, 255, 255)
TEXT_GRAY = (165, 176, 225)

# Block piece colors
PIECE_COLORS = [
    (66, 140, 191),   # blue
    (241, 196, 15),   # yellow
    (231, 76, 60),    # red
    (46, 204, 113),   # green
    (155, 89, 182),   # purple
    (230, 126, 34),   # orange
    (52, 152, 219),   # light blue
    (241, 196, 15),
]

def get_font(size):
    # Try common system fonts, fallback to default
    for name in ["DejaVuSans-Bold.ttf", "Arial Bold.ttf", "Helvetica Bold.ttf"]:
        try:
            return ImageFont.truetype(name, size)
        except:
            pass
    return ImageFont.load_default()

def draw_board(draw, x, y, w, h, rows=20, cols=10, fill_cells=None):
    """Draw simple block-game board grid"""
    cell_w = w // cols
    cell_h = h // rows
    # board border
    draw.rectangle([x, y, x+w, y+h], outline=(80,90,120), width=4)
    # grid lines
    for i in range(1, cols):
        gx = x + i*cell_w
        draw.line([gx, y, gx, y+h], fill=(20,25,40), width=1)
    for i in range(1, rows):
        gy = y + i*cell_h
        draw.line([x, gy, x+w, gy], fill=(20,25,40), width=1)
    
    if fill_cells:
        for r,c,col in fill_cells:
            bx = x + c*cell_w + 2
            by = y + r*cell_h + 2
            bw = cell_w - 4
            bh = cell_h - 4
            draw.rectangle([bx, by, bx+bw, by+bh], fill=col)
            # inner highlight
            draw.rectangle([bx+2, by+2, bx+bw-2, by+bh-2], outline=(255,255,255,60), width=1)

def create_image_1_ana_menu():
    img = Image.new("RGB", (WIDTH, HEIGHT), BG_COLOR)
    draw = ImageDraw.Draw(img)
    
    # Title
    font_title = get_font(96)
    font_sub = get_font(36)
    font_btn = get_font(48)
    
    title = "BLOK YIK"
    # Center
    bbox = draw.textbbox((0,0), title, font=font_title)
    tw = bbox[2]-bbox[0]
    th = bbox[3]-bbox[1]
    draw.text(((WIDTH-tw)//2, 400), title, fill=ACCENT_RED, font=font_title)
    
    sub = "Godot 4 • Masaüstü • Web • Android"
    bbox = draw.textbbox((0,0), sub, font=font_sub)
    sw = bbox[2]-bbox[0]
    draw.text(((WIDTH-sw)//2, 540), sub, fill=TEXT_GRAY, font=font_sub)
    
    # Buttons
    buttons = ["Yeni Oyuna Başla", "Nasıl Oynanır", "Ayarlar", "Yüksek Skorlar", "Hakkında"]
    y = 750
    for btn in buttons:
        bbox = draw.textbbox((0,0), btn, font=font_btn)
        bw = bbox[2]-bbox[0]
        # button panel
        draw.rounded_rectangle([WIDTH//2 - bw//2 - 40, y-30, WIDTH//2 + bw//2 + 40, y+70], radius=20, fill=PANEL_COLOR, outline=(100,120,160), width=2)
        draw.text(((WIDTH-bw)//2, y), btn, fill=TEXT_WHITE, font=font_btn)
        y += 130
    
    img.save(os.path.join(OUTPUT_DIR, "01_ana_menu.png"))
    return img

def create_image_2_nasil_oynanir():
    img = Image.new("RGB", (WIDTH, HEIGHT), BG_COLOR)
    draw = ImageDraw.Draw(img)
    
    font_title = get_font(72)
    font_text = get_font(42)
    
    draw.text((80, 220), "NASIL OYNANIR", fill=ACCENT_RED, font=font_title)
    
    lines = [
        "Satırları doldur.",
        "Sol/Sağ: hareket",
        "Yukarı: döndür",
        "Aşağı: hızla indir",
        "",
        "W: Döndür",
        "A/D: Sol/Sağ",
        "S: Hızlı İndir",
        "Boşluk: Bırak",
        "P: Duraklat"
    ]
    y = 380
    for line in lines:
        draw.text((120, y), line, fill=TEXT_WHITE, font=font_text)
        y += 70
    
    # Draw small board preview
    draw_board(draw, 600, 1000, 400, 600, fill_cells=[
        (18,4,PIECE_COLORS[0]), (18,5,PIECE_COLORS[0]), (17,4,PIECE_COLORS[0]),
        (16,4,PIECE_COLORS[2]), (16,5,PIECE_COLORS[2]), (16,6,PIECE_COLORS[2]),
    ])
    img.save(os.path.join(OUTPUT_DIR, "02_nasil_oynanir.png"))

def create_image_3_oyun_baslangic():
    img = Image.new("RGB", (WIDTH, HEIGHT), BG_COLOR)
    draw = ImageDraw.Draw(img)
    
    # Header
    font_header = get_font(56)
    draw.text((400, 60), "BLOK YIK", fill=TEXT_WHITE, font=font_header)
    
    # Main board area
    board_x, board_y, board_w, board_h = 120, 260, 540, 1080
    draw_board(draw, board_x, board_y, board_w, board_h)
    # Add some pieces
    fill = []
    for r in range(16,20):
        for c in range(2,8):
            fill.append((r,c,PIECE_COLORS[3]))
    fill += [(15,3,PIECE_COLORS[1]), (15,4,PIECE_COLORS[1]), (15,5,PIECE_COLORS[1])]
    draw_board(draw, board_x, board_y, board_w, board_h, fill_cells=fill)
    
    # Info panel
    panel_x, panel_y = 720, 280
    draw.rectangle([panel_x, panel_y, panel_x+300, panel_y+600], fill=PANEL_COLOR, outline=(100,120,160), width=3)
    
    font_info = get_font(40)
    draw.text((panel_x+30, panel_y+40), "PUANLAR", fill=TEXT_GRAY, font=get_font(34))
    draw.text((panel_x+30, panel_y+120), "Skor: 1,250", fill=TEXT_WHITE, font=font_info)
    draw.text((panel_x+30, panel_y+200), "Yüksek Skor: 8,420", fill=TEXT_WHITE, font=font_info)
    draw.text((panel_x+30, panel_y+280), "Seviye: 2", fill=TEXT_WHITE, font=font_info)
    draw.text((panel_x+30, panel_y+360), "Hedef: 7 / 20", fill=TEXT_WHITE, font=font_info)
    
    # Next piece
    draw.rectangle([panel_x, panel_y+520, panel_x+300, panel_y+900], fill=PANEL_COLOR, outline=(100,120,160), width=3)
    draw.text((panel_x+40, panel_y+540), "SONRAKİ", fill=TEXT_GRAY, font=get_font(34))
    # mini piece
    nx = panel_x+80
    ny = panel_y+620
    for i in range(3):
        draw.rectangle([nx+ i*36, ny, nx+ i*36+30, ny+30], fill=PIECE_COLORS[4])
    
    # Controls
    font_small = get_font(28)
    draw.text((panel_x+30, panel_y+960), "Bırak (Boşluk)", fill=TEXT_GRAY, font=font_small)
    draw.text((panel_x+30, panel_y+1020), "Durdur", fill=TEXT_GRAY, font=font_small)
    
    img.save(os.path.join(OUTPUT_DIR, "03_oyun_baslangic.png"))

def create_image_4_seviye_gecis():
    img = Image.new("RGB", (WIDTH, HEIGHT), BG_COLOR)
    draw = ImageDraw.Draw(img)
    
    board_x, board_y, board_w, board_h = 120, 260, 540, 1080
    draw_board(draw, board_x, board_y, board_w, board_h)
    
    # Large level up text
    font_big = get_font(88)
    text = "SEVİYE 2"
    draw.text((WIDTH//2 - 200, HEIGHT//2 - 100), text, fill=(48, 255, 162), font=font_big)
    
    font_sub = get_font(48)
    draw.text((WIDTH//2 - 180, HEIGHT//2 + 80), "Hız arttı!", fill=TEXT_WHITE, font=font_sub)
    
    img.save(os.path.join(OUTPUT_DIR, "04_seviye_gecis.png"))

def create_image_5_yuksek_skorlar():
    img = Image.new("RGB", (WIDTH, HEIGHT), BG_COLOR)
    draw = ImageDraw.Draw(img)
    
    font_title = get_font(80)
    draw.text((WIDTH//2 - 280, 200), "YÜKSEK SKORLAR", fill=ACCENT_RED, font=font_title)
    
    font_row = get_font(44)
    scores = [
        ("1.  ELİF", "15,420"),
        ("2.  AYŞE", "12,880"),
        ("3.  MEHMET", "11,200"),
        ("4.  SEN", "8,420"),
        ("5.  CAN", "7,330"),
    ]
    y = 420
    for name, score in scores:
        draw.text((200, y), name, fill=TEXT_WHITE, font=font_row)
        draw.text((800, y), score, fill=TEXT_GRAY, font=font_row)
        y += 100
    
    img.save(os.path.join(OUTPUT_DIR, "05_yuksek_skorlar.png"))

def create_image_6_ayarlar():
    img = Image.new("RGB", (WIDTH, HEIGHT), BG_COLOR)
    draw = ImageDraw.Draw(img)
    
    font_title = get_font(70)
    draw.text((WIDTH//2 - 150, 200), "AYARLAR", fill=ACCENT_RED, font=font_title)
    
    font_opt = get_font(48)
    options = [
        "Ses efektleri   [✓]",
        "Müzik   [✓]",
        "Müzik Seviyesi",
        "W: Döndür",
        "A/D: Sol/Sağ",
        "S: Hızlı İndir",
    ]
    y = 420
    for opt in options:
        draw.text((250, y), opt, fill=TEXT_WHITE, font=font_opt)
        y += 90
    
    # Slider visual
    draw.rectangle([250, y, 850, y+20], fill=(60,70,90))
    draw.rectangle([250, y, 650, y+20], fill=(100,150,200))
    
    img.save(os.path.join(OUTPUT_DIR, "06_ayarlar.png"))

def create_image_7_duraklat():
    img = Image.new("RGB", (WIDTH, HEIGHT), BG_COLOR)
    draw = ImageDraw.Draw(img)
    
    board_x, board_y, board_w, board_h = 120, 260, 540, 1080
    draw_board(draw, board_x, board_y, board_w, board_h)
    
    # Pause overlay
    overlay = Image.new("RGBA", (WIDTH, HEIGHT), (0,0,0,180))
    img = Image.alpha_composite(img.convert("RGBA"), overlay)
    draw = ImageDraw.Draw(img)
    
    font_pause = get_font(80)
    draw.text((WIDTH//2 - 320, HEIGHT//2 - 200), "OYUN DURAKLATILDI", fill=(255, 210, 60), font=font_pause)
    
    font_btn = get_font(52)
    btns = ["Devam Et", "Yeniden Başlat", "Ana Menü"]
    y = HEIGHT//2 - 50
    for btn in btns:
        bbox = draw.textbbox((0,0), btn, font=font_btn)
        bw = bbox[2]-bbox[0]
        draw.rounded_rectangle([WIDTH//2 - bw//2 - 40, y-30, WIDTH//2 + bw//2 + 40, y+80], radius=20, fill=PANEL_COLOR, outline=(150,170,210), width=3)
        draw.text(((WIDTH-bw)//2, y), btn, fill=TEXT_WHITE, font=font_btn)
        y += 140
    
    img = img.convert("RGB")
    img.save(os.path.join(OUTPUT_DIR, "07_duraklat.png"))

def create_image_8_oyun_bitti():
    img = Image.new("RGB", (WIDTH, HEIGHT), BG_COLOR)
    draw = ImageDraw.Draw(img)
    
    font_title = get_font(80)
    draw.text((WIDTH//2 - 260, HEIGHT//2 - 200), "OYUN BİTTİ", fill=(242, 58, 70), font=font_title)
    
    font_score = get_font(56)
    draw.text((WIDTH//2 - 200, HEIGHT//2 - 80), "Final Skor: 9,840", fill=TEXT_WHITE, font=font_score)
    
    font_desc = get_font(40)
    draw.text((WIDTH//2 - 300, HEIGHT//2 + 40), "Yeni bir oyun başlat veya ana menüye dön.", fill=TEXT_GRAY, font=font_desc)
    
    font_btn = get_font(52)
    btns = ["Yeniden Başlat", "Ana Menüye Dön"]
    y = HEIGHT//2 + 160
    for btn in btns:
        bbox = draw.textbbox((0,0), btn, font=font_btn)
        bw = bbox[2]-bbox[0]
        draw.rounded_rectangle([WIDTH//2 - bw//2 - 40, y-30, WIDTH//2 + bw//2 + 40, y+80], radius=20, fill=PANEL_COLOR, outline=(150,170,210), width=3)
        draw.text(((WIDTH-bw)//2, y), btn, fill=TEXT_WHITE, font=font_btn)
        y += 140
    
    img.save(os.path.join(OUTPUT_DIR, "08_oyun_bitti.png"))

if __name__ == "__main__":
    print("Generating Google Play images...")
    create_image_1_ana_menu()
    create_image_2_nasil_oynanir()
    create_image_3_oyun_baslangic()
    create_image_4_seviye_gecis()
    create_image_5_yuksek_skorlar()
    create_image_6_ayarlar()
    create_image_7_duraklat()
    create_image_8_oyun_bitti()
    print(f"Saved 8 images to {OUTPUT_DIR}")
