class Board

	attr_accessor :pieces, :board
	attr_reader :rows

	def initialize
		@pieces = []
		generate_empty_board
		place_pieces(:white)
		place_pieces(:black)
	end

	def generate_empty_board
		@rows = Array.new(8) { Array.new (8)}
	end

	def place_pieces(color)
		back_row = (color == :white ? 7 : 0)
		fill_dir = (color == :white ? -1 : 1)

		current_row = back_row
		pieces_placed = 0
		until pieces_placed == 12
			8.times do |col|
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

		@rows[i][j] = piece
	end

	def render_board
		@rows.each do |row|
			row.each do |piece|
				print (piece.nil? ? '. ' : "#{piece.render} ")
			end
			print "\n"
		end
		true
	end

end

class InvalidMoveError < StandardError
end

class Piece
	include Marshal
	attr_accessor :pos
	attr_reader :color

	def initialize(color, board, pos)
		@pos = pos
		@color = color
		@board_controller = board
		@board = board.rows
		board.add_piece(self, pos)
	end

	def slide_moves
		forward_dir = (color == :white ? -1 : 1)
		[[forward_dir, 1], [forward_dir, -1]]
	end

	def jump_moves
		forward_dir = (color == :white ? -1 : 1)
		[[2 * forward_dir, 2], [2 * forward_dir, -2]]
	end

	def move_valid?(to_pos)
		unless (self.pos + to_pos).flatten.all? { |x| x.between?(0, 7) }
			return false
		end

		return false unless @board[to_pos[0]][to_pos[1]].nil?
		true
	end

	def perform_slide(to_pos)

		i, j, x, y = self.pos[0], self.pos[1], to_pos[0], to_pos[1]

		raise InvalidMoveError unless move_valid?(to_pos)
		raise InvalidMoveError unless self.slide_moves.include? [(x-i), (y-j)]

		@pos = [x, y]
		@board[x][y] = self
		@board[i][j] = nil

		true
	end

	def perform_jump(to_pos)

		# from and to square coordinates
		i, j, x, y = self.pos[0], self.pos[1], to_pos[0], to_pos[1]
		# jumped square coordinates
		m, n = x - (x - i)/2, y - (y - j)/2
		
		jumped_piece = @board[m][n]

		raise InvalidMoveError unless move_valid?(to_pos)
		raise InvalidMoveError unless self.jump_moves.include? [(x-i), (y-j)]
		raise InvalidMoveError if jumped_piece.nil?
		if jumped_piece.color == @color
			raise InvalidMoveError
		end

		@board_controller.pieces.delete(jumped_piece)
		@board[m][n] = nil
		@board[i][j] = nil
		@pos = [x, y]
		@board[x][y] = self
		true

	end

	def perform_moves!(move_sequence)
		slid = false
		move_sequence.each do |move|
			dy = move[0] - @pos[0]
			dx = move[1] - @pos[1]
			raise InvalidMoveError if slid
			if [dy.abs, dx.abs] == [1, 1]
				p "[dx, dy] is [#{dx}, #{dy}]"
				perform_slide(move)
				slid = true
			elsif [dy.abs, dx.abs] == [2, 2]
				perform_jump(move)
				next
			else
				raise InvalidMoveError
			end
		end
		true
	end

	def render
		@color == :white ? "W" : "B"
	end
end

class KingPiece < Piece


end

