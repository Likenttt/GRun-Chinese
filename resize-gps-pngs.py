import os
from PIL import Image

src_dir_path = "resources/drawables/"
dst_dir_path = "resources-416x416/drawables/"

os.makedirs(dst_dir_path, exist_ok=True)

png_files = [f for f in os.listdir(src_dir_path) if f.endswith('.png')]

for file_name in png_files:
    img = Image.open(src_dir_path + file_name)
    img_resized = img.resize((int(img.width * 2), int(img.height * 2)))
    img_resized.save(dst_dir_path + file_name)
