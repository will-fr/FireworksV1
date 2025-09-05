extends Node

# Global constants and variables for the fireworks game

# Number of columns in the game grid
const NUM_COLUMNS = 6

# Number of rows in the game grid
const NUM_ROWS = 8

const BLOCK_SIZE = 16  # Size of each block in pixels

const TYPES_OF_BLOCK = 4

# pixel offsets of the shells
const TOP_OFFSET:int = 16  # Offset for the top shell
const LEFT_OFFSET:int = 8  # Offset for the left shell

const BOTTOM_SHELL = 1
const TOP_SHELL = 2
const GREEN = 3
const RED = 4
const BLUE = 5
const YELLOW = 6


# Constants
const FIREWORK_SCORE = [20, 30, 50, 100, 300, 500, 1000]
const POP_SCORE = 10  # Points awarded for popping shells


