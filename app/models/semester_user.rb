class SemesterUser < ActiveRecord::Base

  def self.import_users_and_players(committee_members_hash, game_name)
    begin
      game = Game.find_or_create_by!(name: game_name)
    rescue Exception => exception
      p 'ERROR: CANNOT FIND OR CREATE GAME! ' + exception.message
    end
    Player.transaction do
      begin
        committee_members_hash.each do |committee, email_list|
          email_list.each do |email|
            user = User.find_or_create_by(email: email)
            user.update(name: EMAIL_NAME_HASH[email])
            role = Player::ROLE_ASSASSIN
            if SPRING_2016_GAMEMAKERS.include?(email)
              role = Player::ROLE_GAMEMAKER
            elsif SPRING_2016_SPECTATORS.include?(email)
              role = Player::ROLE_SPECTATOR
            end
            Player.create(user_id: user.id, game_id: game.id, role: role, alive: true, committee: committee)
          end
        end
      rescue Exception => exception
        p 'ERROR: IMPORT USER AND PLAYERS FAILED! ' + exception.message
      end
    end
  end

  def self.import_spring_2016_users_and_players
    import_users_and_players(SPRING_2016_COMMITTEE_MEMBERS, SPRING_2016_GAME)
  end

  def self.import_spring_2016_users_and_players_one
    import_users_and_players(SPRING_2016_ONE_PER_COMMITTEE, 'Spring_2016_one')
  end

  def self.import_spring_2016_users_and_players_two
    import_users_and_players(SPRING_2016_TWO_PER_COMMITTEE, 'Spring_2016_two')
  end


  SPRING_2016_GAME = 'Spring_2016'

  SPRING_2016_GAMEMAKERS = Set.new(['gove.elizabeth@berkeley.edu', 'akwan726@gmail.com', 'hkhan9357@gmail.com', 'josephchiang28@gmail.com', 'dakeying@gmail.com'])
  SPRING_2016_SPECTATORS = Set.new(['aldec777@gmail.com', 'adityasubbarao@gmail.com', 'kvyinn@gmail.com', 'davidbliu@gmail.com', 'anthonycleung415@gmail.com', 'evelynwangyen@gmail.com', 'alice.sun94@gmail.com'])

  # Full list for Spring 2016
  SPRING_2016_COMMITTEE_MEMBERS = {
      Committee::AC => ['aldec777@gmail.com', 'adityasubbarao@gmail.com', 'kvyinn@gmail.com', 'davidbliu@gmail.com', 'anthonycleung415@gmail.com', 'evelynwangyen@gmail.com', 'alice.sun94@gmail.com'],
      Committee::EX => ['ericpark1@berkeley.edu', 'jkjhk0823@gmail.com', 'emilyyliu96@gmail.com', 'thomas.warloe@gmail.com', 'd.zhou.5521@berkeley.edu', 'ranul.edirrisinghe@berkeley.edu', 'harukoayabe@gmail.com'],
      Committee::CO => ['joanna_chang@berkeley.edu', 'jchen2714@berkeley.edu', 'anita.chan@berkeley.edu', 'joey.ycchoi@gmail.com', 'dion.dong@berkeley.edu', 'kevinhe0125@gmail.com', 'michaelljlee@berkeley.edu', 'cecilianatasha@berkeley.edu'],
      Committee::CS => ['stephanie.he@berkeley.edu', 'winkywong352@gmail.com', 'aaronchai@berkeley.edu', 'edchoi@berkeley.edu', 'wfang@berkeley.edu', 'kimberlykao@berkeley.edu', 'christine.c.shih@gmail.com', 'tang.yerong@berkeley.edu'],
      Committee::FI => ['vanessalin@berkeley.edu', 'michelleko@berkeley.edu', 'baiyigao@berkeley.edu', 'huie@berkeley.edu', 'william.jiang@berkeley.edu', 'amylin123@berkeley.edu', 'timothyhongtran@berkeley.edu'],
      Committee::HT => ['benjaminlin@berkeley.edu', 'maruoyusuke@gmail.com', 'claire.c@berkeley.edu', 'jfore96@berkeley.edu', 'lenakan123@berkeley.edu', 'fl0424@berkeley.edu', 'lynn.ma@berkeley.edu', 'takahari@berkeley.edu', 'westruong@gmail.com'],
      Committee::IN => ['gove.elizabeth@berkeley.edu', 'akwan726@gmail.com', 'hkhan9357@gmail.com'],
      Committee::MK => ['cristalbanh@berkeley.edu', 'alexparkap@berkeley.edu','jedio@berkeley.edu', 'gary850603@gmail.com', 'sophiah@berkeley.edu', 'cocoj@berkeley.edu', 'lesleylu@berkeley.edu', 'paul.nguyen@berkeley.edu', 'raymond.m.tong@gmail.com', 'mintseng@berkeley.edu'],
      Committee::PD => ['achan6785@gmail.com', 'cindy96@berkeley.edu', 'brittniwlam@berkeley.edu', 'alou@berkeley.edu', 'nathalie.nguyen@berkeley.edu', 'a.stahlhuth@gmail.com', 'jesssunr@berkeley.edu', 'emily.vo@berkeley.edu'],
      Committee::PB => ['acwu15@berkeley.edu', 'cyuan@berkeley.edu', 'ccdavidcheung@berkeley.edu', 'w.cheung@berkeley.edu', 'joycelu@berkeley.edu', 'shenshuyuan@berkeley.edu', 'jessicashi@berkeley.edu', 'iwu18@berkeley.edu', 'd.yu@berkeley.edu'],
      Committee::SO => ['chuang22@berkeley.edu', 'lucinda.tao@hotmail.com', 'kenny.hyun@berkeley.edu', 'ahung@berkeley.edu', 'lkobayashi1@berkeley.edu', 'loganjmoy@berkeley.edu', 'codyni@berkeley.edu', 'qianyuxin@berkeley.edu', 'jingyao.yang@berkeley.edu'],
      Committee::WD => ['josephchiang28@gmail.com', 'dakeying@gmail.com', 'satokoayabe@gmail.com', 'arielchen@berkeley.edu', 'hoping200100@berkeley.edu', 'yjen@berkeley.edu', 'alisont777@gmail.com', 'david.yan@berkeley.edu']
  }

  # For testing purposes
  SPRING_2016_ONE_PER_COMMITTEE = {
      Committee::AC => ['aldec777@gmail.com'],
      Committee::EX => ['ericpark1@berkeley.edu'],
      Committee::CO => ['joanna_chang@berkeley.edu'],
      Committee::CS => ['stephanie.he@berkeley.edu'],
      Committee::FI => ['vanessalin@berkeley.edu'],
      Committee::HT => ['benjaminlin@berkeley.edu'],
      Committee::IN => ['gove.elizabeth@berkeley.edu', 'akwan726@gmail.com', 'hkhan9357@gmail.com'],
      Committee::MK => ['cristalbanh@berkeley.edu'],
      Committee::PD => ['achan6785@gmail.com'],
      Committee::PB => ['acwu15@berkeley.edu'],
      Committee::SO => ['chuang22@berkeley.edu'],
      Committee::WD => ['josephchiang28@gmail.com']
  }

  # For testing purposes
  SPRING_2016_TWO_PER_COMMITTEE = {
      Committee::AC => ['aldec777@gmail.com', 'adityasubbarao@gmail.com'],
      Committee::EX => ['ericpark1@berkeley.edu', 'jkjhk0823@gmail.com'],
      Committee::CO => ['joanna_chang@berkeley.edu', 'jchen2714@berkeley.edu'],
      Committee::CS => ['stephanie.he@berkeley.edu', 'winkywong352@gmail.com'],
      Committee::FI => ['vanessalin@berkeley.edu', 'michelleko@berkeley.edu'],
      Committee::HT => ['benjaminlin@berkeley.edu', 'maruoyusuke@gmail.com'],
      Committee::IN => ['gove.elizabeth@berkeley.edu', 'akwan726@gmail.com', 'hkhan9357@gmail.com'],
      Committee::MK => ['cristalbanh@berkeley.edu', 'alexparkap@berkeley.edu'],
      Committee::PD => ['achan6785@gmail.com', 'cindy96@berkeley.edu'],
      Committee::PB => ['acwu15@berkeley.edu', 'cyuan@berkeley.edu'],
      Committee::SO => ['chuang22@berkeley.edu', 'lucinda.tao@hotmail.com'],
      Committee::WD => ['josephchiang28@gmail.com', 'dakeying@gmail.com']
  }

  # For now contains only spring 2016
  EMAIL_NAME_HASH = {
      'aldec777@gmail.com' => 'Albert Lin', 'adityasubbarao@gmail.com' => 'Aditya Subbarao', 'kvyinn@gmail.com' => 'Kevin Yin', 'davidbliu@gmail.com' => 'David Liu',
      'anthonycleung415@gmail.com' => 'Anthony Leung', 'evelynwangyen@gmail.com' => 'Evelyn Wang', 'alice.sun94@gmail.com' => 'Alice Sun',
      'joanna_chang@berkeley.edu' => 'Joanna Chang', 'jchen2714@berkeley.edu' => 'Jerry Chen', 'joey.ycchoi@gmail.com' => 'Joey Choi', 'cecilianatasha@berkeley.edu' => 'Cecilia Natasha',
      'michaelljlee@berkeley.edu' => 'Michael Lee', 'kevinhe0125@gmail.com' => 'Kevin He', 'dion.dong@berkeley.edu' => 'Dion Dong', 'anita.chan@berkeley.edu' => 'Anita Chan',
      'kimberlykao@berkeley.edu' => 'Kimberly Kao', 'aaronchai@berkeley.edu' => 'Aaron Chai', 'stephanie.he@berkeley.edu' => 'Stephanie He', 'winkywong352@gmail.com' => 'Winky Wong',
      'tang.yerong@berkeley.edu' => 'Emilie Tang', 'christine.c.shih@gmail.com' => 'Christine Shih', 'wfang@berkeley.edu' => 'Wicia Fang', 'edchoi@berkeley.edu' => 'Edward Choi',
      'emilyyliu96@gmail.com' => 'Emily Liu', 'ranul.edirrisinghe@berkeley.edu' => 'Ranul Edirrisinghe', 'harukoayabe@gmail.com' => 'Haruko Ayabe',
      'jkjhk0823@gmail.com' => 'JaeHoon Kim', 'thomas.warloe@gmail.com' => 'Thomas Warloe', 'ericpark1@berkeley.edu' => 'Eric Park', 'd.zhou.5521@berkeley.edu' => 'David Zhou',
      'william.jiang@berkeley.edu' => 'William Jiang', 'michelleko@berkeley.edu' => 'Michelle Ko', 'vanessalin@berkeley.edu' => 'Vanessa Lin', 'huie@berkeley.edu' => 'Eugene Hui',
      'timothyhongtran@berkeley.edu' => 'Timothy Tran', 'baiyigao@berkeley.edu' => 'Baiyi Gao', 'amylin123@berkeley.edu' => 'Amy Lin',
      'lynn.ma@berkeley.edu' => 'Lynn Ma', 'benjaminlin@berkeley.edu' => 'Ben Lin', 'maruoyusuke@gmail.com' => 'Yusuke Maruo', 'claire.c@berkeley.edu' => 'Claire Chen', 'lenakan123@berkeley.edu' => 'Lena Kan',
      'jfore96@berkeley.edu' => 'Ninah Fore', 'westruong@gmail.com' => 'Wesley Truong', 'takahari@berkeley.edu' => 'Natsuki Takahari', 'fl0424@berkeley.edu' => 'Felicia Lin',
      'akwan726@gmail.com' => 'Andrea Kwan', 'gove.elizabeth@berkeley.edu' => 'Liz Gove', 'hkhan9357@gmail.com' => 'Hammad Khan',
      'cocoj@berkeley.edu' => 'Coco Jiang', 'jedio@berkeley.edu' => 'Nancy Chen', 'sophiah@berkeley.edu' => 'Sophia Huang', 'gary850603@gmail.com' => 'Gary Huang', 'raymond.m.tong@gmail.com' => 'Raymond Tong',
      'alexparkap@berkeley.edu' => 'Alex Park', 'cristalbanh@berkeley.edu' => 'Cristal Banh', 'paul.nguyen@berkeley.edu' => 'Paul Nguyen', 'lesleylu@berkeley.edu' => 'Lesley Lu', 'mintseng@berkeley.edu' => 'Min Tseng',
      'acwu15@berkeley.edu' => 'Angela Wu', 'ccdavidcheung@berkeley.edu' => 'David Cheung', 'cyuan@berkeley.edu' => 'Cindy Yuan', 'd.yu@berkeley.edu' => 'Darren Yu',
      'iwu18@berkeley.edu' => 'Iris Wu', 'w.cheung@berkeley.edu' => 'William Cheung', 'jessicashi@berkeley.edu' => 'Jessica Shi', 'joycelu@berkeley.edu' => 'Joyce Lu', 'shenshuyuan@berkeley.edu' => 'Shuyuan Shen',
      'achan6785@gmail.com' => 'Arnold Chan', 'jesssunr@berkeley.edu' => 'Rui Sun', 'nathalie.nguyen@berkeley.edu' => 'Nathalie Nguyen', 'a.stahlhuth@gmail.com' => 'Andrew Stahlhuth',
      'cindy96@berkeley.edu' => 'Cindy Kim', 'alou@berkeley.edu' => 'Andrew Lou', 'brittniwlam@berkeley.edu' => 'Brittni Lam', 'emily.vo@berkeley.edu' => 'Emily Vo',
      'chuang22@berkeley.edu' => 'Chris Huang', 'loganjmoy@berkeley.edu' => 'Logan Moy', 'codyni@berkeley.edu' => 'Cody Ni', 'jingyao.yang@berkeley.edu' => 'Jingyao (Nancy) Yang',
      'kenny.hyun@berkeley.edu' => 'Kenny Yoo', 'lucinda.tao@hotmail.com' => 'Lulu Tao', 'qianyuxin@berkeley.edu' => 'Winnie Xin', 'ahung@berkeley.edu' => 'Angela Hung', 'lkobayashi1@berkeley.edu' => 'Lauren Kobayashi',
      'arielchen@berkeley.edu' => 'Ariel Chen', 'satokoayabe@gmail.com' => 'Satoko Ayabe', 'david.yan@berkeley.edu' => 'David Yan', 'hoping200100@berkeley.edu' => 'Brian Ho',
      'josephchiang28@gmail.com' => 'Joseph Chiang', 'yjen@berkeley.edu' => 'Yiming Jen', 'alisont777@gmail.com' => 'Alison Tang', 'dakeying@gmail.com' => 'Dake Ying'
  }
end
