module GpxDirections
  module Calculators
    # Helpers related to sorting.
    module Sorting
      module_function

      def quick_sort!(ary, low_idx, high_idx)
        to_sort = [[low_idx, high_idx]]

        until to_sort.empty?
          start_idx, end_idx = to_sort.pop

          next if start_idx >= end_idx

          pivot_idx = (start_idx + end_idx) / 2
          ary[start_idx], ary[pivot_idx] = ary[pivot_idx], ary[start_idx]

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

      # Also reorders the Array.
      def quick_select!(ary, low_idx, high_idx, target_idx)
        start_idx = low_idx
        end_idx = high_idx

        loop do
          ary[start_idx], ary[target_idx] = ary[target_idx], ary[start_idx]

          pivot = yield(ary[start_idx])
          i = start_idx + 1
          j = end_idx

          loop do
            i += 1 while (i <= end_idx) && (yield(ary[i]) <= pivot)
            j -= 1 while yield(ary[j]) > pivot

            if i < j
              ary[i], ary[j] = ary[j], ary[i]
            else
              break
            end
          end

          ary[start_idx], ary[j] = ary[j], ary[start_idx]

          if j == target_idx
            return pivot
          elsif j > target_idx
            end_idx = j - 1
          else
            start_idx = j + 1
          end
        end
      end
    end
  end
end
