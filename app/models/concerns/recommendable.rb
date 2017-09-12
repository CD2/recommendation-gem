module Recommendable
  extend ActiveSupport::Concern

  included do
    has_one :recommendation_document, as: :recommendable, inverse_of: :recommendable, class_name: 'Recommendation::Document'
    has_many :votes_as_voter, as: :voter, inverse_of: :voter, class_name: 'Recommendation::Vote'
    has_many :votes_as_votable, as: :votable, inverse_of: :voter, class_name: 'Recommendation::Vote'

    def recommendation_document
      super || create_recommendation_document!
    end

    def tag_with(*args)
      args.extract_options!.each do |tag, weight|
        r_document.static_tags[tag.to_s] = weight
      end
      args.each do |tags|
        Array.wrap(tags).each { |tag| r_document.static_tags[tag.to_s] ||= 1 }
      end
      r_document.save
    end

    def tags_hash
      r_document.tags_cache.with_indifferent_access
    end

    def tags
      tags_hash.map do |tag, weight|
        { name: tag, weight: weight }
      end
    end

    def recalculate_tags
      r_document.recalculate_tags.map do |tag, weight|
        { name: tag, weight: weight }
      end
    end

    def recalculate_tags!
      r_document.recalculate_tags
      r_document.save!
      tags
    end

    def recommendation_score_for(subject)
      0
    end

    def self.recommend_to(subject)
      Recommendation::Document.recommend(all, subject)
    end

    def vote_up(votable)
      vote = votes_as_voter.find_or_initialize_by(votable: votable)
      vote.update(weight: 1)
    end

    def vote_down(votable)
      vote = votes_as_voter.find_or_initialize_by(votable: votable)
      vote.update(weight: -1)
    end

    def unvote(votable)
      votes_as_voter.find_by(votable: votable)&.destroy
    end

    private

    def r_document
      recommendation_document
    end
  end
end
