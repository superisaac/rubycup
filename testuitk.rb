require 'tk'

root = TkRoot.new() { title "Packing Example" }

button = TkButton.new(root) { text "First, rightmost" }
button.pack("side"=>"right", "fill"=>"y")

entry = TkEntry.new(root).pack("side"=>"top", "fill"=>"x")
entry.insert(0, "Entry on the top")

label = TkLabel.new() { text "to the right" }
label.pack("side"=>"right")

image = TkPhotoImage.new('file'=>"background.gif", 'height'=>50)
img_label = TkLabel.new(root) { image image }.pack("anchor"=>"e")

text = TkText.new(root) { width 20; height 5 }.pack("side"=>"left")
text.insert('end', "Left in canvas")

TkMessage.new(root) { text "Message in the Bottom" }.pack("side"=>"bottom")

Tk.mainloop()
