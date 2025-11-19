extends Node

# difficulty settings
const EASY_LEVEL = 1
const HARD_LEVEL = 2
const LEGENDARY_LEVEL = 3
const IMPOSSIBLE_LEVEL = 4

#The current difficulty level
var difficulty_level = Globals.EASY_LEVEL

# The maximum difficulty level selectable in the game.
var max_difficulty_level = Globals.EASY_LEVEL

# Global constants and variables for the fireworks game

# Number of columns in the game grid
var NUM_COLUMNS = 5
# Maximum number of columns allowed
const MAX_COLUMNS = 7

# Number of rows in the game grid
const NUM_ROWS = 8

const BLOCK_SIZE = 16  # Size of each block in pixels

const TYPES_OF_BLOCK = 4

# pixel offsets of the shells
const TOP_OFFSET:int = 16  # Offset for the top shell
const MINI_LEFT_OFFSET:int = 8  # Offset for the left shell
var SIZE_CONTAINER = NUM_COLUMNS * BLOCK_SIZE #todo: fix the const/var mess.
var LEFT_OFFSET = (136.0 -SIZE_CONTAINER) / 2.0


	

const BOTTOM_SHELL = 1
const TOP_SHELL = 2
const GREEN = 3
const RED = 4
const BLUE = 5
const YELLOW = 6
const SHELL_NAMES = ["","BOTTOM", "TOP", "GREEN", "RED", "BLUE", "YELLOW"]

# Constants
const FIREWORK_SCORE = [20, 30, 50, 100, 300, 500, 1000]
const POP_SCORE = 10  # Points awarded for popping shells
