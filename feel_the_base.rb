require 'mongo'
require 'json'
require_relative 'config'

db = Mongo::Client.new([ "#{DB_HOST}:#{DB_PORT}" ], :database => DATABASE)
db[:categories].find().delete_many
db[:activities].find().delete_many
db[:categories].insert_many([{:title => 'Спортивное направление'}, {:title => 'Академическая деятельность'}, {:title => 'Волонтерская деятельность'}])

sport = nil
db[:categories].find(:title => 'Спортивное направление').each do |document|
  sport = document
  break
end

academ = nil

db[:categories].find(:title => 'Академическая деятельность').each do |document|
  academ = document
  break
end

volunteer = nil

db[:categories].find(:title => 'Волонтерская деятельность').each do |document|
  volunteer = document
  break
end


db[:activities].insert_many([
    {
        title: 'Участие в соревновании',
        type: 'permanent',
        category: sport,
        price: 100
    },
    {
        title: 'Первое место в соревновании',
        type: 'permanent',
        category: sport,
        price: 300
    },
    {
        title: 'Написание статьи',
        type: 'permanent',
        category: academ,
        price: 1000
    },
    {
        title: 'Проведение занятий в рамках кружка',
        type: 'qunatity',
        category: academ,
        price: 100
    },
    {
        title: 'волонтер мероприятия',
        type: 'hourly',
        category: volunteer,
        price: 50
    }
                            ])
