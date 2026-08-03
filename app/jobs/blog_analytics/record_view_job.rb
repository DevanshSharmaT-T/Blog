# frozen_string_literal: true

module BlogAnalytics
  class RecordViewJob < ApplicationJob
    queue_as :default

    def perform(blog_id:, date: nil)
      date ||= Date.current

      sql = <<~SQL
        INSERT INTO blog_analytics
          (id, blog_id, recorded_date, views, unique_visitors, social_shares, backlinks, source)
        VALUES
          (gen_random_uuid(), $1, $2, 1, 0, 0, 0, 'internal')
        ON CONFLICT (blog_id, recorded_date)
        DO UPDATE SET views = blog_analytics.views + 1
      SQL

      BlogAnalytic.connection.exec_query(sql, "RecordView", [ blog_id, date ])
    end
  end
end
