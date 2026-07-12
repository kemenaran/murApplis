# This script tests the behavior of the shuffling function used by `murApplis`.
#
# It is also a first attempt at literate-style programming: this page is generated from
# the `murApplis_tests.rb` file using [Rocco](https://github.com/rtomayko/rocco). You can
# also view [murApplis_tests.rb](./murApplis_tests.rb) directly.

### Requirements

# We recall that the required behavior of this custom shuffling function is to
# randomize an array of values such as **no item is at the same place before and
# after the shuffle**.
#
# On top of that, we'd like to ensure the usual properties that we expect of a shuffling
# function: it should operate in *constant timing* (that is always the same duration for
# sets of the same length) and the resulting distribution should be *unbiased* (although
# this is more for algorithmic correctness: we probably don't really care if a wall of
# app icons is slightly biased).

### Shuffling

# Here is our shuffling function. It takes an array of items, and randomize them in a way
# that ensures no item occupies the same position before and after the shuffle. The array
# is modified in-place (for efficiency reasons), but the resulting array is also returned
# for chaining method calls.

def shuffle! array
    # The shuffle is made in *n - 1* iterations, where *n* is the number of items in the array.

    (array.count - 1).downto(0) do |i|
    
        # For each iteration, we look at the *i* first items of the array.
        # That means the first iteration will look at all the items in the array, the second
        # at all the items but the last one, the third at the first *(n - 2)* items, and so on.
        
        # A random number is chosen in the range *(0..i)*.
        n = rand(i)
        
        # The *i*-th item is then swapped with the item at the randomly chosen position.
        array[i], array[n] = array[n], array[i]
        
        # The algorithm loops over until the range of the examined items is reduced to the
        # first item. 
    end
    return array
end

#### Why does it work?

# Of course, this is a description of the *Knuth-Fisher-Yates* algorithm. It is quite simple,
# and guarantees an unbiased shuffling if correctly implemented. But how does it guarantee our
# custom constraint, that no items should be at the same place before and after?

# The answer lies in the way the algorithm operates. As we wrote above, it works by swapping items
# *(n - 1)* times. One of the item to be swapped is selected randomly - but the other is always
# at the end of the examined range. At each iteration, the range is decreased by one.
# That means the algorithm ensures that **all the items of the array will be swapped at least once**:
# at the first iteration the last item will be swapped, then the second-to-last item, and so on.

# But how does this ensure that an item won't ever be swapped back at its original place? After
# all, the other item to be swapped is chosen randomly.

# However the random is not over the whole range
# of the array: the range is reduced at each iteration. The positions are only selected among the
# ones that have not been swapped yet.

# For instance, let's say the last item of the array is "Z". Once the first iteration swapped "Z"
# with another randomly-chosen item, the random range is decreased by one. This means that **no item
# can ever be swapped at the last position anymore**: even if a future random position selects "Z" to be
# swapped again, it is impossible that it comes back at the last position.

# By extension, no item can be swapped back at the same place: this ensures all our constraints are
# respected.

### Tests

# The testing plan is the following:
#
#   * Assert conformance of the shuffling function using a naive (and wrong) shuffling
#     function; expect it to fail,
#   
#   * Assert conformance of the real shuffling function; expect it to succeed.
#
#   * Assert that the sample standard deviation converges to 0 when the samples count increase.

### Asserting initial conditions

# The basis of our conformance tests is a method that, given a grid and the shuffled grid,
# ensure that no item is at the same place before and after the shuffle.
def assert_positions_different grid, shuffled_grid

    # For this, we use a simple reduce: for each index, check that the items are different
    # in the original and in the shuffled grid.
    # 
    # The result is placed in an accumulator, which will turn to 'false' as soon as a duplicate
    # item is detected.
    shuffled_grid.reduce(true) do |is_different, letter|
        is_different and (grid.find_index(letter) != shuffled_grid.find_index(letter))
    end
end

# Now we also need a function that can perform this conformance check on a *set* of shuffled grids.
#
# This function takes an original grid, and an array of shuffled grid.
def print_grid_assertions grid, shuffled_grids
    
    # For each shuffled grid, it prints its conformance status to the standard output.
    all_grids_valid = true
    shuffled_grids.each do |shuffled_grid| 
        if assert_positions_different(grid, shuffled_grid)
            puts "[OK]    " + shuffled_grid.map{|x| x.to_s + " "}.to_s
        else
            puts "[Error] " + shuffled_grid.map{|x| x + " "}.to_s
            all_grids_valid = false
        end
    end
    
    # At the end, it reports the global conformance of the grids — that is whether the shuffle
    # was correct for all of them, or if some had duplicated items.
    if all_grids_valid == true
        puts "Success: On all shuffle, all items are in a different position " \
             "before and after the shuffle."
    else
        puts "Failure: On some shuffles, one or more items are in the same position " \
             "before and after the shuffle."     
    end
end

# And finally, we need a function to generate a set of *n* shuffled grids.
# The shuffling method to use can be specified as an optional parameter - so we can
# test different algorithms.
def shuffled_grids grid_to_shuffle, count, shuffleFunction=method(:shuffle!)
    # For this, we fill an array with *n* copies of the grid to be shuffled.
    (Array.new count).
        fill(grid_to_shuffle).
        # Then the shuffling function is called one for each object of the array.
        collect { |item| shuffleFunction.call item.dup }
end

### Printing statistics

# This part deals with the distribution uniformity tests.

# The base of it is a simple function that calculates the [standard deviation](http://en.wikipedia.org/wiki/Standard_deviation)
# for a set of samples. The samples are given as an array of probabilities: the first
# sample has a probability of `dist[0]`, the second sample of dist[1], and so on.
def sample_standard_deviation dist
    n = dist.count
    # The mean is the sum of all samples divided by the number of samples.
    mean = dist.reduce(&:+) / n
    # There is the formula for the variance.
    v = (1.0 / (n - 1)) * dist.map { |x| (x - mean) ** 2 }.reduce(&:+)
    # As the variance is the squared standard deviation, return the square root of the variance.
    s = Math.sqrt(v) 
end

# We also need a function to compute and print the statistics of our samples.
# This one takes an array of shuffled grids.
def print_shuffled_randomness grids

    # (When we dump the content of shuffled arrays to the console, it can be useful
    # to give them a nice formatting.)
    def prettyprint hash
        hash.each do |(key, value)|
             p key.map{|x| x + " "}.to_s + " => " + value.to_s
        end
    end
    
    # First we regroup all the samples by occurence, and we count them.
    occurrences = grids.reduce(Hash.new(0)){ |hash, grid| hash[grid] +=1 ; hash }
    
    # Then we compute the outcomes - i.e. the probability of each occurence.   
    outcomes = occurrences.inject(occurrences) do |hash, (key, value)|
        # The probability of an sample is the number of occurences of a sample
        # divided by the total number of samples.
        hash[key] = (value / grids.count.to_f)
        hash
    end
    
    # The next line can be uncommented to print the outcomes. 
    #puts "Probability of each occurence: "; prettyprint outcomes
    
    # Then we compute the sum of the outcomes (which should be equal to 1).
    outcomes_sum = outcomes.reduce(0){ |sum, (key, value)| sum += value}
    
    # At the end, we print the sample standard deviation to the screen.
    s = sample_standard_deviation outcomes.values
    puts "Sum of outcomes: #{outcomes_sum}\tSample standard deviation: #{s}";
end

### Helpers

# To ensure tests correctness, we need a shuffle method that fails to meet the requirements.
# By using it, we can check that tests fail correctly when they must do so.
def naive_shuffle! array
    shuffled_array = array
    array.count.times do
        # This naive shuffle just swap two random items in the array.
        # 
        # So we're sure that there will be cases where items are at the same position before
        # and after. Plus the resulting distribution is probably biased.
        n = rand(shuffled_array.count);
        m = rand(shuffled_array.count)
        shuffled_array[m], shuffled_array[n] = shuffled_array[n], shuffled_array[m]
    end
    return array
end

### Wrapping up

# Time to run our tests!
# First, create some tests data.
# We represent a grid of applications by an array of application titles.
apps_grid = ["Facebook", "TestFlight", "Maps", "Pages", "Safari"]

# Now, test that the shuffle method responds to constraints.
# For this, we shuffle the grid several times, store all the different shufflings, and ensure
# that all these outcomes satify the requirements.

# A good demonstration can be made using 10 differents shuffles per test.
samples_count = 10

# Let's generate a serie of shuffled grids using our bogus `naive_shuffle` function.
puts "Naive shuffle:"
bad_samples = shuffled_grids apps_grid, samples_count, method(:naive_shuffle!)
# Naturally, we expect our tests to fail, with several shufflings exhibiting items at the same place.
print_grid_assertions apps_grid, bad_samples

# Now let's generate a serie of shuffled grids using our custom shuffle function.
puts ""
puts "Good shuffle:"
shuffled_grids = shuffled_grids apps_grid, samples_count
# This time, we expect all the tests to be successfull.
print_grid_assertions apps_grid, shuffled_grids

puts ""

#### Testing for bias

# One last thing: we'd like to test that the suffled distribution is not biased. That is,
# is there the same probability to get each outcome?
#
# For this, we compute the sample standard deviation of a serie of shuffled grids. The
# actual value of the standard deviation doesn't have much meaning — but if the distribution
# is unbiased, when we increase the number of samples, we should see it converge to zero.

puts "For 100 samples"
shuffled_samples = shuffled_grids apps_grid, 100
print_shuffled_randomness shuffled_samples

puts "For 1000 samples"
shuffled_samples = shuffled_grids apps_grid, 1000
print_shuffled_randomness shuffled_samples

puts "For 10000 samples"
shuffled_samples = shuffled_grids apps_grid, 10000
print_shuffled_randomness shuffled_samples
