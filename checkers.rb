class Board
	attr_accessor :pieces

	def initialize
		@pieces = []
		generate_empty_board
		place_pieces(:white)
		place_pieces(:black)
	end

	def generate_empty_board
		@board = Array.new(8) { Array.new (8)}
	end

	def place_pieces(color)
		back_row = (color == :white ? 7 : 0)
		fill_dir = (color == :white ? -1 : 1)

		current_row = back_row
		pieces_placed = 0
		until pieces_placed == 12
			8.times do |col|
				p "col is #{col}"
				p "current row is #{current_row}"
				if (current_row + col) % 2 == 1
					Piece.new(color, self, [current_row, col])
					pieces_placed += 1
					p pieces_placed
				end
			end
			current_row += fill_dir
		end
		true
	end

	def add_piece(piece, pos)
		@pieces << piece

		i = pos[0]
		j = pos[1]

		@board[i][j] = piece
	end

	def render_board
		@board.each do |row|
			row.each do |piece|
				print (piece.nil? ? '. ' : "#{piece.render} ")
			end
			print "\n"
		end
		true
	end

end

class Piece
	attr_accessor :pos
	attr_reader :color

	def initialize(color, board, pos)
		@pos = pos
		@color = color
		@board = board
		@board.add_piece(self, pos)
	end


	def slide_moves
		forward_dir = (color == :white ? -1 : 1)
		[[1, forward_dir], [-1, forward_dir]]
	end

	def jump_moves
		forward_dir = (color == :white ? -1 : 1)
		@jump_moves = [[2, 2 * forward_dir], [-2, 2 * forward_dir]]
	end

	def render
		@color == :white ? "W" : "B"
	end
end

class KingPiece < Piece


end