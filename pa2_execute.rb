# Calvin Wang
# COSI 105B
# Movies-2

require './movie_data.rb'

def load
	puts "Would you like to run base/training set pair tests?"
	print "('yes' or 'no', anything else to quit): "

	prompt = $stdin.gets.chomp

	if prompt == 'yes'
		puts "\nFile name (u1 to u5)"
		print "(return to quit): "

		id = $stdin.gets.chomp
		run_tests(id)

	elsif prompt == 'no'
		view_info("ml-100k")

	else
		puts "Quitting..."
	end
end

def run_tests file = nil
	puts "\nCreating MovieData object..."
	x = MovieData.new("ml-100k", file)
	test = x.load_data()

	puts "Running test..."
	x.run_test

	puts """
	Test set mean: #{x.movie_test.mean}
	Test set std dev: #{x.movie_test.stddev}
	Test set root mean square: #{x.movie_test.rms}
	"""
end

def view_info link
	x = MovieData.new("#{link}")
	x.load_data()

	puts "\nPlease select one:\n1. User info\t2. Movie stats\t3. Most popular movies"
	print "(anything else to quit): "
	prompt = $stdin.gets.chomp.to_i

	if (prompt == 1) || (prompt == 2) then
		print "Input ID: "
		id = $stdin.gets.chomp.to_i

		if (prompt == 1 && x.user_reviews[id] != nil) then
			puts "1. List movies reviewed\t2. Load most similar users\n3. Compare to specific user"
			print "(anything else to quit): "
			choice = $stdin.gets.chomp.to_i

			if (choice == 1) then list_movies_reviewed(id, x)
			elsif (choice == 2) then load_similar_users(id, x)
			elsif (choice == 3) then compare_users(id, x)
			else puts "quitting..." end

		elsif (prompt == 2 && x.m_stats[id] != nil) then

			list_movie_stats(id, x)

		else
			puts "ID not found in set."
		end 
	end

	if (prompt == 3) then
		load_popularity_list(x)
	end

	puts ""
end

def list_movies_reviewed id, x
	print "\n[user #{id} has reviewed #{x.user_reviews[id].length} movies:"
		
	prev = 0
	x.user_reviews[id].movies.keys.sort.each do |e|	# sort by key (movie id)
		temp = e.to_s.split('')[0].to_i		# check first digit
		if temp > prev then
			print "]\n  [#{e}"				# each line has a different initial digit
		else
			print ", #{e}"					# this is to improve readability
		end
		prev = temp
	end
	puts "]"
end

def load_similar_users id, x
	pop_queue(x.most_similar(id, "top"), "10 Most Similar Users to User #{id}", "top")
	pop_queue(x.most_similar(id, "bottom"), "10 Least Similar Users to User #{id}", "bottom")
end

def compare_users id, x
	print "User to compare to: "
	id2 = $stdin.gets.chomp.to_i

	if (x.user_reviews[id2] != nil) then
		puts "Degree of similarity from #{id} to #{id2}: #{x.similarity(id, id2).round(3)}"
		puts "Degree of similarity from #{id2} to #{id}: #{x.similarity(id2, id).round(3)}"
	else puts "User does not exist" end
end

def list_movie_stats id, x
	puts """
	Overall stats about movie #{id}:
	Times reviewed: #{x.m_stats[id].num_r}
	Total rating: #{x.m_stats[id].total_r}
	Average rating: #{x.m_stats[id].average_r.round(2)}
	Popularity: #{x.popularity(id)}"""
end

def load_popularity_list x
	pop_queue(x.popularity_list("top"), "Top 10 Most Popular Movies", "top")
	pop_queue(x.popularity_list("bottom"), "10 Least Popular Movies", "bottom")
end

def pop_queue q, string, topBot
	puts "\n#{string}"
	if topBot == "top"
		(0...10).each { puts q.pop }
	else
		numElements = q.size
		count = 0
		list = []
		while q.size != 0
			line = q.pop
			if count > numElements - 10
				list.push line
			end
			count = count+1
		end
		list.reverse_each { puts list.pop }
	end
end


load