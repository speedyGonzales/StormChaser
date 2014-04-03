require 'spec_helper'
require 'rake'
require 'pry'


describe Cyclone do

	before(:each) do
		StormChaser::Application.load_tasks
		Rake::Task.define_task(:environment)
		Rake::Task['import:only_5s'].invoke
	end

  describe "#many_cyclone_map_data" do
  	it "returns an array of objects holding tornado data" do
    	@cyclone = Cyclone.all.many_cyclone_map_data

      expect(@cyclone.first.start_lat).to_not be_nil
      expect {@cyclone.first.width}.to raise_error
  	end
  end

  describe "#complete_cyclone_tracks" do
    it "returns an array of cyclones where complete track is true" do
      @cyclone = Cyclone.all.complete_cyclone_tracks

      expect(@cyclone.first.path.complete_track).to be_true
      expect {@cyclone.last.complete_track}.to be_true
    end
  end

  describe "#strongest_cyclones_first" do
    it "returns an array of cyclones sorted in descending order of strength" do
      @cyclone = Cyclone.all.strongest_cyclones_first

      expect(@cyclone.first.f_scale).to eq(5)
    end
  end

  describe "#index_map" do
  	it "returns info for cyclones for main index map: with complete tracks, sorted strongest first, and pulling info specified in many_cyclone_map_data method. Limited to 500. " do
    	@cyclone = Cyclone.index_map
    	@bad_storm = Cyclone.joins(:path).where(paths: {complete_track: false}).first

      expect {@cylone.find(@bad_storm.id)}.to raise_error
  	end
  end

end
