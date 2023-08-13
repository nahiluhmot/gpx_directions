module GpxDirections
  module Calculators
    # Helpers related to sorting.
    module Sorting
      module_function

      def quick_sort!(ary, low_idx, high_idx, &comparator)
        to_sort = [[low_idx, high_idx]]

        until to_sort.empty?
          start_idx, end_idx = to_sort.pop

          if start_idx >= end_idx
            next
          elsif (end_idx - start_idx) < 5
            partition5!(ary, start_idx, end_idx, &comparator)
          else
            partition_idx = partition!(ary, start_idx, end_idx, (start_idx + end_idx) / 2, &comparator)

            to_sort << [start_idx, partition_idx - 1]
            to_sort << [partition_idx + 1, end_idx]
          end
        end

        ary
      end

      # Also reorders the Array.
      def quick_select!(ary, low_idx, high_idx, target_idx, &comparator)
        start_idx = low_idx
        end_idx = high_idx

        loop do
          if (end_idx - start_idx) < 5
            partition5!(ary, start_idx, end_idx, &comparator)

            return target_idx
          end

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

      def median_of_medians!(list, low_idx, high_idx, target_idx, &comparator)
        start_idx = low_idx
        end_idx = high_idx

        loop do
          return start_idx if start_idx == end_idx

          pivot_idx = median_of_medians_pivot!(list, start_idx, end_idx, &comparator)
          partition_idx = partition!(list, start_idx, end_idx, pivot_idx, &comparator)

          if target_idx == partition_idx
            return partition_idx
          elsif partition_idx > target_idx
            end_idx = partition_idx - 1
          else
            start_idx = partition_idx + 1
          end
        end
      end

      def median_of_medians_pivot!(ary, start_idx, end_idx, &comparator)
        idx_diff = end_idx - start_idx

        if idx_diff < 5
          partition5!(ary, start_idx, end_idx, &comparator)

          return (start_idx + end_idx) / 2
        end

        slice_start = start_idx

        while slice_start <= end_idx
          slice_end = (slice_start + 4).clamp(start_idx, end_idx)
          slice_median = (slice_start + slice_end) / 2

          partition5!(ary, slice_start, slice_end, &comparator)

          idx = start_idx + ((slice_start - start_idx) / 5)
          ary[slice_median], ary[idx] = ary[idx], ary[slice_median]

          slice_start += 5
        end

        new_end_idx = start_idx + (idx_diff / 5)
        new_mid_idx = (start_idx + new_end_idx) / 2

        median_of_medians!(ary, start_idx, new_end_idx, new_mid_idx, &comparator)
      end

      def partition5!(ary, start_idx, end_idx)
        i = start_idx + 1

        while i <= end_idx
          j = i

          while (j > start_idx) && (yield(ary[j - 1]) > yield(ary[j]))
            ary[j], ary[j - 1] = ary[j - 1], ary[j]
            j -= 1
          end

          i += 1
        end

        (start_idx + end_idx) / 2
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
