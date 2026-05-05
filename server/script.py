import requests

with open("image.png", "rb") as f:
    b = f.read()

resp = requests.post("https://stonesoup.uk/images", b)
print(resp)
