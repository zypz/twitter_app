class User < ActiveRecord::Base
	 attr_accessor :remember_token
	 has_many :microposts, dependent: :destroy
	 has_many :active_relationships, class_name:  "Relationship",
                                  foreign_key: "follower_id",
                                  dependent:   :destroy
     has_many :following, through: :active_relationships, source: :followed
      
      has_many :passive_relationships, class_name:  "Relationship",
                                   foreign_key: "followed_id",
                                   dependent:   :destroy
      has_many :followers, through: :passive_relationships, source: :follower               

	
	 before_save { self.email = email.downcase }
	 validates :name,  presence: true, length: { maximum: 50 }
	 VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
	 validates :email, presence: true, length: { maximum: 255 },
	                    format: { with: VALID_EMAIL_REGEX },
                        uniqueness: { case_sensitive: false }
  
	 has_secure_password #has_secure_password 方法本身会验证存在性，但是可惜，只会验证有没有密码，因此用户可以创建 “ ”（6 个空格）这样的无效密码
	 validates :password, presence: true, length: { minimum: 6 },allow_nil:true

 # 返回用户的动态流
  def feed
   following_ids = "SELECT followed_id FROM relationships
                     WHERE  follower_id = :user_id"
    Micropost.where("user_id IN (#{following_ids}) OR user_id = :user_id", user_id: id)
  end
# 关注另一个用户
  def follow(other_user)
    active_relationships.create(followed_id: other_user.id)
  end

  # 取消关注另一个用户
  def unfollow(other_user)
    active_relationships.find_by(followed_id: other_user.id).destroy
  end

  # 如果当前用户关注了指定的用户，返回 true
  def following?(other_user)
    following.include?(other_user)
  end

 # 返回指定字符串的哈希摘要
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  # 返回一个随机令牌
  def User.new_token
    SecureRandom.urlsafe_base64
  end

# 为了持久会话，在数据库中记住用户
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end
# 如果指定的令牌和摘要匹配，返回 true
  def authenticated?(remember_token)
  	return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  # 忘记用户
  def forget
    update_attribute(:remember_digest, nil)
  end

# # 实现动态流原型
#   def feed
#     Micropost.where("user_id = ?", id)
#   end

end
