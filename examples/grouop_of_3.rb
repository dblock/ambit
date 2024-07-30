#!/usr/bin/ruby

require 'rubygems'
require 'ambit'

@best_solutions = []
@solutions = []

def choose_group_of_3(remaining_items, groups)
  @solutions << groups if remaining_items.size < 3

  group = [
    Ambit.choose(remaining_items),
    Ambit.choose(remaining_items),
    Ambit.choose(remaining_items)
  ]
  Ambit.fail! if group.uniq.length != group.length # no dups
  Ambit.fail! if groups.any? { |solved_group| solved_group.intersection(group).length > 0 } # any group already contains item
  Ambit.fail! if @best_solutions.any? { |best_solution| best_solution.any? { |best_solution_group| best_solution_group.intersection(group).length > 1 } } # any two intersecting in a previous solution

  remaining_items = remaining_items.reject { |item| group.include?(item) }
  choose_group_of_3(remaining_items, groups + [group])
end

def solve
  items = (1..12).to_a

  @solutions = []

  begin
    choose_group_of_3(items, [])
    Ambit.fail!
  rescue Ambit::ChoicesExhausted
  end

  best_solution = @solutions.sort_by { |s| -s.length }.first
  p best_solution
  @best_solutions << best_solution
end

3.times do
  solve
end
