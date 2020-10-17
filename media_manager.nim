import strformat

var media: string
try:
  media = readFile("data.dat")
  echo "Existing Media:"
  echo media
  echo "Add Media"
except IOError:
  echo "No media! Please add media to start:"

while true:
  echo "Title:"
  let title: string = readLine(stdin)
  if (title == ""):
    break

  media.add(title & "\n")
  writeFile("data.dat", media)
  echo fmt"Added ""{title}"""
