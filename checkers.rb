class Game


end

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
		@board = board
		@rows = board.rows
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

		return false unless @rows[to_pos[0]][to_pos[1]].nil?
		true
	end

	def perform_slide(board, to_pos)

		i, j, x, y = self.pos[0], self.pos[1], to_pos[0], to_pos[1]

		raise InvalidMoveError unless move_valid?(to_pos)
		raise InvalidMoveError unless self.slide_moves.include? [(x-i), (y-j)]

		board.pieces.select { |piece| piece.pos == self.pos }.last.pos = [x, y]
		board.rows[x][y] = self
		board.rows[i][j] = nil

		true
	end

	def perform_jump(board, to_pos)

		# from and to square coordinates
		i, j, x, y = self.pos[0], self.pos[1], to_pos[0], to_pos[1]
		# jumped square coordinates
		m, n = x - (x - i)/2, y - (y - j)/2
		
		jumped_piece = board.rows[m][n]

		raise InvalidMoveError unless move_valid?(to_pos)
		raise InvalidMoveError unless self.jump_moves.include? [(x-i), (y-j)]
		raise InvalidMoveError if jumped_piece.nil?
		if jumped_piece.color == @color
			raise InvalidMoveError
		end

		board.pieces.delete(jumped_piece)
		board.rows[m][n] = nil
		board.rows[i][j] = nil
		board.pieces.select { |piece| piece.pos == self.pos }.last.pos = [x, y]
		board.rows[x][y] = self
		
		true
	end

	def perform_moves!(board, move_sequence)
		slid = false
		move_sequence.each do |move|
			dy = move[0] - @pos[0]
			dx = move[1] - @pos[1]
			raise InvalidMoveError if slid
			if [dy.abs, dx.abs] == [1, 1]
				perform_slide(board, move)
				slid = true
			elsif [dy.abs, dx.abs] == [2, 2]
				perform_jump(board, move)
				next
			else
				raise InvalidMoveError
			end
		end
		true
	end

	def valid_move_seq?(move_sequence)
		future_board = Marshal::load(Marshal.dump(@board))
		begin
			perform_moves!(future_board, move_sequence)
		rescue
			return false
		end
		return true
	end

	def perform_moves(move_sequence)
		if valid_move_seq?(move_sequence)
			perform_moves!(@board, move_sequence)
			return true
		else
			false
		end
	end

	def render
		@color == :white ? "W" : "B"
	end

end

class KingPiece < Piece


end

class HumanPlayer
	def get_move
		move_array = []
		move_array << get_piece
		move_array.concat get_sequence
	end

	def get_piece
		puts "Pick a piece to move."
		gets.chomp.split("").map(&:to_i)
	end

	def get_sequence
		move_sequence = []
		puts "Enter a location or series of locations to move the piece."
		seq = gets.chomp.split("").map(&:to_i)
		until seq.empty?
			move_sequence << seq.shift(2)
		end
		move_sequence
	end
end

