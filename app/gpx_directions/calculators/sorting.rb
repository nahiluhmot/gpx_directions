module GpxDirections
  module Calculators
    # Helpers related to sorting.
    module Sorting
      module_function

      # Also reorders the Array.
      def quick_select!(ary, low_idx, high_idx, target_idx, &comparator)
        start_idx = low_idx
        end_idx = high_idx

        loop do
          return target_idx if end_idx == start_idx

          partition_idx = partition!(ary, start_idx, end_idx, target_idx, &comparator)

          if partition_idx == target_idx
            return target_idx
          elsif partition_idx > target_idx
            end_idx = partition_idx - 1
          else
            start_idx = partition_idx + 1
          end
        end
      end

      def partition!(ary, start_idx, end_idx, pivot_idx)
        ary[start_idx], ary[pivot_idx] = ary[pivot_idx], ary[start_idx]

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

        j
      end
    end
  end
end
