class SemesterUser < ActiveRecord::Base

  SPRING_2016_GAME = 'Spring 2016'
  SPRING_2016_COMMITTEE_MEMBERS = {Committee::AC => ['aldec777@gmail.com', 'adityasubbarao@gmail.com', 'kvyinn@gmail.com', 'davidbliu@gmail.com', 'anthonycleung415@gmail.com', 'evelynwangyen@gmail.com', 'alice.sun94@gmail.com'],
                                   Committee::EX => ['ericpark1@berkeley.edu', 'jkjhk0823@gmail.com', 'emilyyliu96@gmail.com', 'thomas.warloe@gmail.com', 'd.zhou.5521@berkeley.edu', 'ranul.edirrisinghe@berkeley.edu', 'harukoayabe@gmail.com'],
                                   Committee::CS => ['stephanie.he@berkeley.edu', 'winkywong352@gmail.com', 'aaronchai@berkeley.edu', 'edchoi@berkeley.edu', 'wfang@berkeley.edu', 'kimberlykao@berkeley.edu', 'christine.c.shih@gmail.com', 'tang.yerong@berkeley.edu'],
                                   Committee::CO => ['joanna_chang@berkeley.edu', 'jchen2714@berkeley.edu', 'anita.chan@berkeley.edu', 'joey.ycchoi@gmail.com', 'dion.dong@berkeley.edu', 'kevinhe0125@gmail.com', 'michaelljlee@berkeley.edu', 'cecilianatasha@berkeley.edu'],
                                   Committee::FI => ['vanessalin@berkeley.edu', 'michelleko@berkeley.edu', 'baiyigao@berkeley.edu', 'huie@berkeley.edu', 'william.jiang@berkeley.edu', 'amylin123@berkeley.edu', 'timothyhongtran@berkeley.edu'],
                                   Committee::HT => ['benjaminlin@berkeley.edu', 'maruoyusuke@gmail.com', 'claire.c@berkeley.edu', 'jfore96@berkeley.edu', 'lenakan123@berkeley.edu', 'fl0424@berkeley.edu', 'lynn.ma@berkeley.edu', 'takahari@berkeley.edu', 'westruong@gmail.com'],
                                   Committee::IN => ['gove.elizabeth@berkeley.edu', 'akwan726@gmail.com', 'hkhan9357@gmail.com'],
                                   Committee::MK => ['cristalbanh@berkeley.edu', 'alexparkap@berkeley.edu','jedio@berkeley.edu', 'gary850603@gmail.com', 'sophiah@berkeley.edu', 'cocoj@berkeley.edu', 'lesleylu@berkeley.edu', 'paul.nguyen@berkeley.edu', 'raymond.m.tong@gmail.com', 'mintseng@berkeley.edu'],
                                   Committee::PD => ['achan6785@gmail.com', 'cindy96@berkeley.edu', 'brittniwlam@berkeley.edu', 'alou@berkeley.edu', 'nathalie.nguyen@berkeley.edu', 'a.stahlhuth@gmail.com', 'jesssunr@berkeley.edu', 'emily.vo@berkeley.edu'],
                                   Committee::PB => ['acwu15@berkeley.edu', 'cyuan@berkeley.edu', 'ccdavidcheung@berkeley.edu', 'w.cheung@berkeley.edu', 'joycelu@berkeley.edu', 'shenshuyuan@berkeley.edu', 'jessicashi@berkeley.edu', 'iwu18@berkeley.edu', 'd.yu@berkeley.edu'],
                                   Committee::SO => ['chuang22@berkeley.edu', 'lucinda.tao@hotmail.com', 'kenny.hyun@berkeley.edu', 'ahung@berkeley.edu', 'lkobayashi1@berkeley.edu', 'loganjmoy@berkeley.edu', 'codyni@berkeley.edu', 'qianyuxin@berkeley.edu', 'jingyao.yang@berkeley.edu'],
                                   Committee::WD => ['josephchiang28@gmail.com', 'dakeying@gmail.com', 'satokoayabe@gmail.com', 'arielchen@berkeley.edu', 'hoping200100@berkeley.edu', 'yjen@berkeley.edu', 'alisont777@gmail.com', 'david.yan@berkeley.edu']}



  def self.import_users_and_players(committee_members_hash, game_name)
    game = Game.where(name: game_name).first
    if game.nil?
      puts 'ERROR: No game found with name: ' + game_name
      return
    end
    committee_members_hash.each do |committee, email_list|
      email_list.each do |email|
        user = User.find_or_create_by(email: email)
        role = Player::ROLE_ASSASSIN
        if committee.eql? Committee::IN
          role = Player::ROLE_GAMEMAKER
        end
        Player.create(user_id: user.id, game_id: game.id, role: role, alive: true, committee: committee)
      end
    end
  end

  def self.import_spring_2016_users_and_players
    import_users_and_players(SPRING_2016_COMMITTEE_MEMBERS, 'Spring 2016')
  end
end
