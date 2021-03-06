# encoding: utf-8

class Submission < ActiveRecord::Base
  STATUS_MAPPING = {
    "nadesłany" => :sent, "u redaktora" => :editor, "w recenzji" => :review,
    "przyjęty" => :positive, "odrzucony" => :negative, "do poprawy" => :correction
  }
  POLISH = 'polski'
  ENGLISH = 'angielski'
  validates :status, presence: true, inclusion: STATUS_MAPPING.keys
  validates :language, presence: true, inclusion: [POLISH, ENGLISH]
  validates :received, presence: true
  validates :polish_title, presence: true, if: -> (r){ r.language == POLISH}
  validates :english_title, presence: true, if: -> (r){ r.language == ENGLISH}
    
  has_many :authorships, dependent: :destroy
  has_many :article_revisions, dependent: :destroy
  belongs_to :person
  belongs_to :issue
  MAX_LENGTH = 80

  def title
    if !self.polish_title.blank?
      cut_text(self.polish_title)
    elsif !self.english_title.blank?
      cut_text(self.english_title)
    else
      "[BRAK TYTUŁU]"
    end
  end

  def abstract
    if !self.polish_abstract.blank?
      self.polish_abstract
    elsif !self.english_abstract.blank?
      self.english_abstract
    else
      "[BRAK STRESZCZENIA]"
    end
  end

  def keywords
    if !self.polish_keywords.blank?
      self.polish_keywords
    elsif !self.english_keywords.blank?
      self.english_keywords
    else
      "[BRAK SŁÓW KLUCZOWYCH]"
    end
  end

  def corresponding_author
    authorship = self.authorships.where(corresponding: true).first
    if authorship
      authorship.author
    else
      "[BRAK AUTORA]"
    end
  end
  
  def issue_title
    if self.issue
      issue.title
    else
      "[BRAK PRZYNALEŻNOŚCI DO NUMERU]"
    end
  end
  
  def author
    authorship = self.authorships.where(corresponding: true).first
    if authorship
      authorship.person
    else
      nil
    end
  end
  
  def editor
    if self.person
      self.person.full_name
    else
      "[BRAK REDAKTORA]"
    end
  end

  def full_title
    "#{corresponding_author}, #{title}"
  end

  def reviews
    self.article_revisions.flat_map do |revision|
      revision.reviews
    end
  end

  private
  def cut_text(text)
    if text.size > MAX_LENGTH
      text[0...MAX_LENGTH] + "..."
    else
      text
    end
  end

end
