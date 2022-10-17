-- {"id":1788,"ver":"1.0.4","libVer":"1.0.0","author":"TechnoJo4"}
local qs = Require("url").querystring

local text = function(v)
	return v:text()
end

local defaults = {
	meta_offset = 1,
	ajax_hot = "/ajax/hot-novels",
	ajax_latest = "/ajax/latest-novels",
	ajax_chapters = "/ajax/chapter-option",
	appendURLToInfoImage = true,
	searchTitleSel = ".novel-title",

	baseUrlInLinks = false,
	hasCloudFlare = false,
	hasSearch = true,
	chapterType = ChapterType.HTML
}

function defaults:search(data)
	-- search gives covers but they're in some weird aspect ratio
	local doc = GETDocument(qs({ q = data[QUERY], page = data[PAGE] }, self.baseURL .. "/search"))

	return map(doc:selectFirst(".list-cat2"):select("div.item a"), function(v)
			local novel = Novel()
			novel:setImageURL(v:selectFirst("img"):attr("src"))
			novel:setTitle(v:attr("title"))
			novel:setLink(v:attr("href"):gsub(self.baseURL, ""))
			return novel
		end)
end

function defaults:getPassage(url)
	local htmlElement = GETDocument(self.baseURL .. url)
	local title = htmlElement:selectFirst("a.truyen-title"):text()
	htmlElement = htmlElement:selectFirst("div.chapter-content")

	-- Remove/modify unwanted HTML elements to get a clean webpage.
	htmlElement:removeAttr("style") -- Hopefully only temporary as a hotfix
	htmlElement:select("script"):remove()
	htmlElement:select("ins"):remove()
	htmlElement:select("div.ads"):remove()
	htmlElement:select("div[align=\"left\"]:last-child"):remove() -- Report error text

	-- Chapter title inserted before chapter text.
	htmlElement:child(0):before("<h1>" .. title .. "</h1>");

	return pageOfElem(htmlElement)
end

function defaults:parseNovel(url, loadChapters)
	local doc = GETDocument(self.baseURL .. url)
	local info = NovelInfo()

	local elem = doc:selectFirst(".info"):children()
	local title = doc:selectFirst("h3.title"):text()
	info:setTitle(title)

	local meta_offset = elem:size() < 3 and self.meta_offset or 0

	local function meta_links(i)
		return map(elem:get(meta_offset + i):select("a"), text)
	end

	info:setAuthors(meta_links(0))
	--info:setAlternativeTitles(meta_links(1))
	info:setGenres(meta_links(1))
	--info:setStatus( ({
	--	Ongoing = NovelStatus.PUBLISHING,
	--	Completed = NovelStatus.COMPLETED
	--})[elem:get(meta_offset + 3):select("a"):text()] )

	info:setImageURL((self.appendURLToInfoImage and self.baseURL or "") .. doc:selectFirst("div.book img"):attr("src"))
	info:setDescription(table.concat(map(doc:select("div.desc-text p"), text), "\n"))

	if loadChapters then
		--local id = doc:selectFirst("div[data-novel-id]"):attr("data-novel-id")
		local i = 0
		-- doc:selectFirst(".list-chapter"):children(),
		info:setChapters(AsList(map(
				doc:selectFirst(".list-chapter"):select("li a"),
				function(v)
					local chap = NovelChapter()
					chap:setLink(v:attr("href"):gsub(self.baseURL, ""))
					chap:setTitle(v:attr("title"):gsub(title .. " - ", ""))
					chap:setOrder(i)
					i = i + 1
					return chap
				end)))
	end

	return info
end

---@param url string
function defaults:shrinkURL(url)
	return url:gsub(self.baseURL, "")
end

---@param url string
function defaults:expandURL(url)
	return self.baseURL .. url
end

local function novelData(baseURL, _self)
	_self = setmetatable(_self or {}, { __index = function(_, k)
		local d = defaults[k]
		return (type(d) == "function" and wrap(_self, d) or d)
	end })
	_self["baseURL"] = baseURL
	if not _self["ajax_base"] then
		_self["ajax_base"] = baseURL
	end
	_self["listings"] = {
		Listing("Hot", false, function()
			return map(GETDocument(_self.ajax_base .. _self.ajax_hot):selectFirst(".list-cat2"):select("div.item a"), function(v)
				local novel = Novel()
				novel:setImageURL(v:selectFirst("img"):attr("src"))
				novel:setTitle(v:attr("title"))
				novel:setLink(v:attr("href"):gsub(baseURL, ""))
				return novel
			end)
		end),
		Listing("Latest", false, function()
			return map(GETDocument(_self.ajax_base .. _self.ajax_latest):select("div.item a"), function(v)
				local novel = Novel()
				novel:setTitle(v:text())
				novel:setLink(v:attr("href"):gsub(baseURL, ""))
				return novel
			end)
		end)
	}
	return _self
end

return novelData("https://novelnb.com", {
	id = 1789,
	name = "NovelNB",
	imageURL = "",

	hasCloudFlare = true,
	meta_offset = 0,
	ajax_hot = "/list/hot-novel",
	ajax_latest = "/search?type=latest",
	ajax_chapters = "/chapter-option",
	searchListSel = "list.list-truyen.col-xs-12",
	searchTitleSel = ".img-hover"
})
