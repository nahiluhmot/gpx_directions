module GpxDirections
  # Intercation with a SQLite DB.
  class DB
    BATCH_SIZE = 500

    TABLES = {
      nodes: {
        columns: {id: :integer, lat: :real, lon: :real},
        indexes: {index_nodes_on_lat_lon: [:lat, :lon]},
        primary_key: [:id]
      },
      ways: {
        columns: {id: :integer, name: :text},
        indexes: {},
        primary_key: [:id]
      },
      node_ways: {
        columns: {node_id: :integer, way_id: :integer},
        indexes: {index_node_ways_on_node_id: [:node_id]},
        primary_key: [:node_id, :way_id]
      }
    }.freeze

    def self.build(path)
      new(SQLite3::Database.new(path))
    end

    def initialize(sqlite)
      @sqlite = sqlite
    end

    def seed_db(osm_map)
      create_tables

      osm_map.nodes.each_slice(BATCH_SIZE, &method(:insert_nodes))

      osm_map.ways.each_slice(BATCH_SIZE) do |ways|
        insert_ways(ways)

        insert_node_ways(ways)
      end
    end

    def build_map_for_bounds(bounds_ary)
      nodes = bounds_ary.each_slice(BATCH_SIZE).flat_map(&method(:load_nodes_in_bounds))
      ways = nodes.each_slice(BATCH_SIZE).flat_map(&method(:load_ways_for_nodes))

      Osm::Map.new(nodes:, ways:)
    end

    private

    def create_tables
      TABLES.each do |table, config|
        cols, idxs, primary_key = config.values_at(:columns, :indexes, :primary_key)

        serialized_cols = cols
          .map { |column, type| "#{column} #{type} NOT NULL" }
          .join(",")
        serialized_primary_key = primary_key.join(",")
        create_table_query = <<~SQL
          CREATE TABLE IF NOT EXISTS #{table} (
            #{serialized_cols},
            PRIMARY KEY (#{serialized_primary_key})
          )
        SQL

        execute(create_table_query)

        idxs.each do |index_name, index_cols|
          create_index_query = <<~SQL
            CREATE INDEX IF NOT EXISTS #{index_name}
            ON #{table} (#{index_cols.join(",")})
          SQL

          execute(create_index_query)
        end
      end
    end

    def insert_nodes(nodes)
      vars = Array.new(nodes.length, "(?,?,?)").join(",")
      query = <<~SQL
        INSERT INTO nodes (id, lat, lon) VALUES #{vars}
        ON CONFLICT DO
        UPDATE SET lat = excluded.lat, lon = excluded.lon
      SQL
      args = nodes.flat_map do |node|
        [node.id.to_s, node.lat.to_digits, node.lon.to_digits]
      end

      execute(query, args)
    end

    def insert_ways(ways)
      vars = Array.new(ways.length, "(?,?)").join(",")
      query = <<~SQL
        INSERT INTO ways (id, name) VALUES #{vars}
        ON CONFLICT DO
        UPDATE SET name = excluded.name
      SQL
      args = ways.flat_map { |way| [way.id.to_s, way.name] }

      execute(query, args)
    end

    def insert_node_ways(ways)
      node_ways = ways.flat_map do |way|
        way.node_ids.map { |node_id| [node_id.to_s, way.id.to_s] }
      end

      vars = Array.new(node_ways.length, "(?,?)").join(",")
      query = <<~SQL
        INSERT INTO node_ways (node_id, way_id) VALUES #{vars}
        ON CONFLICT DO NOTHING
      SQL
      args = node_ways.flatten

      execute(query, args)
    end

    def load_nodes_in_bounds(bounds_ary)
      bounds_condition = Array
        .new(
          bounds_ary.length,
          "((nodes.lat BETWEEN ? AND ?) AND (nodes.lon BETWEEN ? AND ?))"
        )
        .join(" OR ")
      query = <<~SQL
        SELECT nodes.id, nodes.lat, nodes.lon
        FROM nodes
        WHERE #{bounds_condition}
      SQL
      args = bounds_ary.flat_map do |bounds|
        [bounds.min_lat, bounds.max_lat, bounds.min_lon, bounds.max_lon].map(&:to_digits)
      end

      rows = execute(query, args)

      rows.map do |(id_num, lat_float, lon_float)|
        id = id_num.to_s.to_sym
        lat = BigDecimal(lat_float, 16)
        lon = BigDecimal(lon_float, 16)

        Osm::Node.new(id:, lat:, lon:)
      end
    end

    def load_ways_for_nodes(nodes)
      rows = execute(
        <<~SQL,
          SELECT
            ways.id,
            ways.name,
            GROUP_CONCAT(node_ways.node_id, ",") AS node_ids
          FROM node_ways
          INNER JOIN ways ON node_ways.way_id = ways.id
          WHERE node_ways.node_id IN (#{Array.new(nodes.length, "?").join(",")})
          GROUP BY ways.id, ways.name
        SQL
        nodes.map { |node| node.id.to_s }
      )

      rows.map do |id_str, name, node_ids_str|
        id = id_str.to_s.to_sym
        node_ids = node_ids_str.split(",").map(&:to_sym)

        Osm::Way.new(id:, name:, node_ids:)
      end
    end

    def execute(query, args = [])
      GpxDirections.logger.debug { "executing sql query: #{query}" }

      @sqlite.execute(query, args)
    end
  end
end
