module GpxDirections
  # Helpers related to sorting.
  module Sorting
    module_function

    def in_place_sort_by!(ary, low_idx, high_idx)
      to_sort = [[low_idx, high_idx]]

      until to_sort.empty?
        start_idx, end_idx = to_sort.shift

        next if start_idx >= end_idx

        pivot_val = yield(ary[start_idx])

        i = start_idx + 1
        j = end_idx

        loop do
          i += 1 while (i <= end_idx) && (yield(ary[i]) <= pivot_val)
          j -= 1 while yield(ary[j]) > pivot_val

          if i < j
            ary[i], ary[j] = ary[j], ary[i]
          else
            break
          end
        end

        ary[start_idx], ary[j] = ary[j], ary[start_idx]

        to_sort << [start_idx, j - 1]
        to_sort << [j + 1, end_idx]
      end

      ary
    end
  end
end
