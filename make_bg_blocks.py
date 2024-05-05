#!/usr/bin/env python3

# Helper functions
def separateFirstWord(text, lowercaseFirst=True):
	space = text.find(" ")
	command = text
	arg = ""
	if space >= 0:
		command = text[0:space]
		arg = text[space+1:]
	if lowercaseFirst:
		command = command.lower()
	return (command, arg)

def parseNumber(number):
	if number in aliases:
		return parseNumber(aliases[number])
	if number.startswith("$"):
		return int(number[1:], 16)
	return int(number)

def parseMetatileTile(tile):
	""" Parse the nametable value for one tile """
	# Read the tile number in the format of x,y starting from the specified base
	if tile.find(",") >= 0:
		split = [parseNumber(s) for s in tile.split(",")]
		return split[0]+split[1]*16
	else:
		return parseNumber(tile)
	return 0

# Globals
aliases = {}
block = None
palette = 0
all_blocks = []

# Read and process the file
with open("bg_blocks.txt") as f:
    text = [s.rstrip() for s in f.readlines()]

def saveBlock():
	if block == None:
		return
	block['palette'] = palette
	all_blocks.append(block)

for line in text:
	if not len(line):
		continue
	if line.startswith("#"): # comment
		continue
	if line.startswith("+"): # new block
		saveBlock()
		# Reset to prepare for the new block
		priority = False
		block = {"name": line[1:], "tiles": []}
		continue
	word, arg = separateFirstWord(line)

	if word == "alias":
		name, value = separateFirstWord(arg)
		aliases[name] = value
	elif word == "palette":
		palette = parseNumber(arg)
	elif word == "t": # add tiles
		split = arg.split(" ")
		for tile in split:
			block["tiles"].append(parseMetatileTile(tile))
	elif word == "q": # add four tiles at once
		tile = parseMetatileTile(arg)
		block["tiles"] = [tile, tile+1, tile+16, tile+17]
	elif word == "w": # add four tiles at once, but wide
		tile = parseMetatileTile(arg)
		block["tiles"] = [tile, tile+1, tile+2, tile+3]

# Save the last one
saveBlock()

# Generate the output that's actually usable in the game
outfile = open("bg_blockdata.s", "w")

outfile.write('; This is automatically generated. Edit "bg_blocks.txt" instead\n')
#outfile.write('.export BlockTopLeft, BlockTopRight, BlockBottomLeft, BlockBottomRight, BlockPalette\n')

# --------------------------------

# Block appearance information
corners = ["TopLeft", "TopRight", "BottomLeft", "BottomRight"]
for corner, cornername in enumerate(corners):
	outfile.write(".proc Block%s\n" % cornername)
	for b in all_blocks:
		outfile.write('  .byte $%.2x ; %s\n' % (b['tiles'][corner], b['name']))
	outfile.write(".endproc\n\n")

outfile.write(".proc BlockPalette\n")
for b in all_blocks:
	p = b['palette'] & 3
	outfile.write('  .byte $%.2x ; %s\n' % (p | (p<<2) | (p<<4) | (p<<6), b['name']))
outfile.write(".endproc\n\n")

outfile.close()

# Generate the enum in a separate file
outfile = open("bg_blockenum.s", "w")
outfile.write('; This is automatically generated. Edit "bg_blocks.txt" instead\n')
outfile.write('.enum Block\n')
for i, b in enumerate(all_blocks):
	outfile.write('  %s = %d\n' % (b['name'], i))
outfile.write('.endenum\n\n')

outfile.close()
