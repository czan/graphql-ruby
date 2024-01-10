# frozen_string_literal: true

module GraphQL
  module Tracing
    class SentryTracing < PlatformTracing

      self.platform_keys = {
        'lex' => "graphql.lex",
        'parse' => "graphql.parse",
        'validate' => "graphql.validate",
        'analyze_query' => "graphql.analyze",
        'analyze_multiplex' => "graphql.analyze",
        'execute_multiplex' => "graphql.execute",
        'execute_query' => "graphql.execute",
        'execute_query_lazy' => "graphql.execute",
        'execute_field' => "graphql.execute",
        'execute_field_lazy' => "graphql.execute"
      }

      def platform_trace(platform_key, trace_method, data, &block)
        return yield unless Sentry.initialized?

        Sentry.with_child_span(op: platform_key, start_timestamp: Sentry.utc_now.to_f) do |span|
          result = block.call
          span.finish

          if trace_method == "execute_query" && data
            description = [data[:query].selected_operation.operation_type, data[:query].selected_operation_name].compact.join(' ')
            description = 'GraphQL Query' if description.empty?

            span.set_description(description)
            span.set_data('graphql.document', data[:query].query_string)
            span.set_data('graphql.operation.name', data[:query].selected_operation_name)
            span.set_data('graphql.operation.type', data[:query].selected_operation.operation_type)
          end

          result
        end
      end

      def platform_field_key(field)
        "graphql.#{field.path}"
      end

      def platform_authorized_key(type)
        "graphql.authorized.#{type.graphql_name}"
      end

      def platform_resolve_type_key(type)
        "graphql.resolve_type.#{type.graphql_name}"
      end
    end
  end
end
