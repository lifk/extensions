-- {"id":1787,"ver":"0.1.0","libVer":"0.1.0","author":"Xanvial"}

local baseURL = "https://www.webnovelpub.com/"
local settings = {}

--- @param chapterURL string
--- @return string
local function getPassage(chapterURL)
	local lines = GETDocument(baseURL .. chapterURL):selectFirst("div.chapter-container"):select("p")
	local passage = "\n"
	map(lines, function(e)
		passage = passage .. e:text() .. "\n"
	end)
	return passage
end

--- @param novelURL string
--- @return NovelInfo
local function parseNovel(novelURL)
	local novelInfo = NovelInfo()
	local novelURL = baseURL .. "novel/" .. novelURL
	local document = GETDocument(novelURL)

	novelInfo:setImageURL(document:selectFirst("div.fixed-img"):select("figure"):select("img"):attr("data-src"))

	local info = document:selectFirst("div.novel-info")
	novelInfo:setTitle(info:selectFirst("h1"):text())
	novelInfo:setAuthors({ info:selectFirst("div.author"):selectFirst("span"):text() })
	--novelInfo:setAlternativeTitles({ info:get(0):text() })
	--novelInfo:setGenres({ info:get(1):text() })

	novelContainer = document:selectFirst("div.novel-body")
	novelInfo:setDescription(novelContainer:selectFirst(p.description):text())

	local chapterPage = GETDocument(novelURL .. "/chapters")
	local chaptersDocs = chapterPage:selectFirst("ul.chapter-list"):select("li")

	local chapterCount = 0

	local chapters = map2flat(chaptersDocs, function(e)
		return e:select("a")
	end, function(e)
		local chapter = NovelChapter()
		chapter:setTitle(e:attr("title"))
		chapter:setLink(e:attr("href"))
		chapter:setOrder(chapterCount)
		chapterCount = chapterCount + 1
		return chapter
	end)
	novelInfo:setChapters(AsList(chapters))
	return novelInfo
end

--- @param filters table @of applied filter values [QUERY] is the search query, may be empty
--- @param reporter fun(v : string | any)
--- @return Novel[]
local function search(filters, reporter)
	return {}
end

return {
	id = 1787,
	name = "Light Novel Pub",
	baseURL = baseURL,

	-- Optional values to change
	imageURL = "https://static.lightnovelpub.com/content/img/lightnovelpub/logo.png",
	hasCloudFlare = true,
	hasSearch = true,

	-- Must have at least one value
	listings = {
		Listing("Default", true, function(data)
			local d = GETDocument(baseURL ..
					"stories-17091737/genre-all/order-popular/status-all/p-" ..
					1)
			local cont = d:selectFirst("div.container")
			local itemList = cont:selectFirst("ul.novel-list")
			local items = itemList:select("li.novel-item")

			return map(items, function(e)
				local novel = Novel()
				local title = e:selectFirst("h4"):selectFirst("a")
				novel:setTitle(title:attr("title"))
				novel:setLink(title:attr("href"))
				novel:setImageURL(e:selectFirst("img"):attr("data-src"))
				return novel
			end)
		end),
	},

	-- Optional if usable
	searchFilters = {
		TextFilter(17871, "RANDOM STRING INPUT"),
	},
	settings = {
		TextFilter(1, "RANDOM STRING INPUT"),
	},

	-- Default functions that have to be set
	getPassage = getPassage,
	parseNovel = parseNovel,
	search = search,
	updateSetting = function(id, value)
		settings[id] = value
	end
}
