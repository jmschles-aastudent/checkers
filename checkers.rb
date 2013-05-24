#encoding: UTF-8

require 'colorize'

class Game

	def initialize
		@board = Board.new
		@player1 = HumanPlayer.new(:white)
		@player2 = HumanPlayer.new(:black)
		@current_player = @player1
		run
	end

	def take_turn(player)

		@board.render_board
		puts "#{player.color.to_s.capitalize}'s turn!"
		begin
			move = player.get_move
			handle_move(move, player)
		rescue StandardError => e
			puts "Error: #{e.message}"
		else
			@current_player = (@current_player == @player1 ? @player2 : @player1)
			return
		end

	end

	def run
		while true
			take_turn(@current_player)
		end
	end

	def handle_move(move, player)
		piece_locator = move.shift
		piece = @board.rows[piece_locator[0]][piece_locator[1]]
		raise InvalidMoveError if piece.nil?
		raise InvalidMoveError unless piece.color == player.color
		@board.perform_moves(piece, move)
	end

end

class Board

	attr_accessor :pieces, :board
	attr_reader :rows

	def initialize
		@pieces = []
		generate_empty_board
		place_pieces(:white)
		place_pieces(:black)
		true
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
		true
	end

	def render_board
		alternator = 0
		@rows.each do |row|
			row.each do |piece|
				if alternator % 2 == 0
					print (piece.nil? ? '  ' : "#{piece.symbol} ").colorize( :background => :blue)
				else
					print (piece.nil? ? '  ' : "#{piece.symbol} ").colorize( :background => :red)
				end
				alternator += 1
			end
			alternator += 1
			print "\n"
		end
		true
	end

	def move_valid?(from_pos, to_pos)
		unless (from_pos + to_pos).flatten.all? { |x| x.between?(0, 7) }
			return false
		end

		return false unless @rows[to_pos[0]][to_pos[1]].nil?
		true
	end

	def perform_slide(from_pos, to_pos)

		i, j, x, y = from_pos[0], from_pos[1], to_pos[0], to_pos[1]

		piece = @rows[i][j]

		raise InvalidMoveError unless move_valid?(from_pos, to_pos)
		raise InvalidMoveError unless piece.slide_moves.include? [(x-i), (y-j)]

		piece.pos = [x, y]
		@rows[x][y] = piece
		@rows[i][j] = nil
		piece.convert_to_king if piece.king_eligible?

		true
	end

	def perform_jump(from_pos, to_pos)

		# from and to square coordinates
		i, j, x, y = from_pos[0], from_pos[1], to_pos[0], to_pos[1]
		# jumped square coordinates
		m, n = x - (x - i)/2, y - (y - j)/2
		
		piece = @rows[i][j]
		jumped_piece = @rows[m][n]

		raise InvalidMoveError unless move_valid?(from_pos, to_pos)
		raise InvalidMoveError unless piece.jump_moves.include? [(x-i), (y-j)]
		raise InvalidMoveError if jumped_piece.nil?
		if jumped_piece.color == piece.color
			raise InvalidMoveError
		end

		@pieces.delete(jumped_piece)
		@rows[m][n] = nil
		piece.pos = [x, y]
		@rows[x][y] = piece
		@rows[i][j] = nil
		piece.convert_to_king if piece.king_eligible?

		true
	end

	def perform_moves!(piece, move_sequence)
		slid = false
		move_sequence.each do |move|
			dy = move[0] - piece.pos[0]
			dx = move[1] - piece.pos[1]
			raise InvalidMoveError if slid
			if [dy.abs, dx.abs] == [1, 1]
				perform_slide(piece.pos, move)
				slid = true
			elsif [dy.abs, dx.abs] == [2, 2]
				perform_jump(piece.pos, move)
			else
				raise InvalidMoveError
			end
		end
		
		true
	end

	def valid_move_seq?(piece, move_sequence)
		future_board = Marshal::load(Marshal.dump(self))
		duped_piece = future_board.pieces.select do |p|
			p.pos == piece.pos
		end.last
		begin
			future_board.perform_moves!(duped_piece, move_sequence)
		rescue
			return false
		else
			return true
		end
	end

	def perform_moves(piece, move_sequence)
		if valid_move_seq?(piece, move_sequence)
			perform_moves!(piece, move_sequence)
			return true
		else
			false
		end
	end

end

class InvalidMoveError < StandardError
end

class Piece
	include Marshal
	attr_accessor :pos
	attr_reader :color, :slide_moves, :jump_moves, :symbol

	def initialize(color, board, pos)
		@pos = pos
		@color = color
		@symbol = (color == :white ? 'W' : 'B')
		@board = board
		@rows = board.rows
		board.add_piece(self, pos)
		forward_dir = (color == :white ? -1 : 1)
		@slide_moves = [[forward_dir, 1], [forward_dir, -1]]
		@jump_moves = [[2 * forward_dir, 2], [2 * forward_dir, -2]]
	end

	def king_eligible?
		end_row = (color == :white ? 0 : 7)
		return true if @pos[0] == end_row
		false
	end

	def convert_to_king
		@slide_moves = [[1, 1], [1, -1], [-1, 1], [-1, -1]]
		@jump_moves = [[2, 2], [2, -2], [-2, 2], [-2, -2]]

		@symbol = (@color == :white ? "w" : "b")
	end

end


class HumanPlayer

	attr_reader :color

	def initialize(color)
		@color = color
	end

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
		seq = gets.chomp.delete(" ").split("").map(&:to_i)
		until seq.empty?
			move_sequence << seq.shift(2)
		end
		move_sequence
	end
end
