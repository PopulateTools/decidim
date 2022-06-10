import { max, histogram, extent } from "d3-array";
import { scaleTime, scaleLinear } from "d3-scale";
import { timeMonth } from "d3-time";
import { select } from "d3-selection";
import { axisBottom, axisLeft } from "d3-axis";

export default class ActivityBrowser {
  constructor(data) {
    this.arr = this.csvToArray(data);

    // State variables
    this.cachedUsers = null;
    this.cachedTotalUsers = null;
    this.cachedContributions = null;
    this.cachedTotalContributions = null;
    this.nodeSelected = null;
    this.dates = this.getDates(this.arr);
    this.timerActive = false;
    this.datesInterval = null;
    this.currentDateIndex = 0;
    this.selectedRange = 'all';
  }

  run() {
    this.refreshData(this.arr, true);

    // Enable tooltip
    tippy('.users span');
    tippy('.contributions span');

    // Click on date ranges
    $(document).on("click", '[data-time-range]', (e) => {
      $('[data-time-range]').removeClass('bold');

      const $element = $(e.currentTarget);
      $element.addClass('bold');

      this.selectedRange = $element.data('time-range');
      let filteredData = this.arr;
      const today = new Date();
      let fromRange;
      switch(this.selectedRange) {
        case 'month':
          fromRange = new Date(new Date().setDate(today.getDate() - 30))
          filteredData = this.filterDataByDateRange(fromRange, this.arr);
          this.refreshData(filteredData, false);
          break;
        case 'year':
          fromRange = new Date(new Date().setDate(today.getDate() - 365))
          filteredData = this.filterDataByDateRange(fromRange, this.arr);
          this.refreshData(filteredData, false);
          break;
        case 'all':
          this.refreshData(this.arr, true);
          break;
      }
    });

    // Click on timer
    $(document).on("click", '[data-timer]', (e) => {
      if (this.timerActive) {
        this.timerActive = false;
        clearInterval(this.datesInterval);

        this.resetActiveElements();
        $('div.date').html('');
        $(this).html('Start timer');
      } else {
        this.timerActive = true;
        $(this).html('Stop timer');
        this.datesInterval = setInterval(setDateInterval, 2000);
        $('div.date').html(this.dates[this.currentDateIndex].toLocaleDateString());
        const filteredData = this.filterDataByDate(this.dates[this.currentDateIndex], this.arr);
        this.refreshData(filteredData, false);

        function setDateInterval() {
          this.currentDateIndex++;
          $('div.date').html(this.dates[this.currentDateIndex].toLocaleDateString());
          const filteredData = this.filterDataByDate(this.dates[this.currentDateIndex], this.arr);
          this.refreshData(filteredData, false);
        }
      }
    });

    // Click on contributons
    $(document).on("click", 'ul.contributons span', (e) => {
      if(this.nodeSelected === null) {
        const $element = $(e.currentTarget);
        this.nodeSelected = {type: $element.data('type'), id: $element.data('id') }
      } else {
        this.nodeSelected = null;
      }
    });

    // Click on users
    $(document).on("click", 'ul.users span', (e) => {
      if(this.nodeSelected === null) {
        const $element = $(e.currentTarget);
        this.nodeSelected = {type: $element.data('type'), id: $element.data('id') }
      } else {
        this.nodeSelected = null;
      }
    });

    // Mouse over on contributions
    $(document).on("mouseenter", 'ul.contributions span', (e) => {
      if(this.timerActive || this.nodeSelected) { return false; }

      let $element = $(e.currentTarget);
      let id = $element.data('id').toString();
      let type = $element.data('type');

      const filteredData = this.arr.filter(i => ((i.item_type === type && i.item_id === id) || (i.target_type === type && i.target_id === id)));
      this.refreshData(filteredData, false);
    })

    $(document).on("mouseleave", "ul.contributions span", (e) => {
      if(this.timerActive || this.nodeSelected) { return false; }
      this.refreshData(this.arr, true);
    });

    // Mouse over on users
    $(document).on("mouseenter", 'ul.users span', (e) => {
      if(this.timerActive || this.nodeSelected) { return false; }

      let $element = $(e.currentTarget);
      let id = $element.data('id').toString();

      const filteredData = this.arr.filter(i => (i.decidim_user_id === id || (i.target_type === 'user' && i.target_id === i.decidim_user_id)));
      this.refreshData(filteredData, false);
    })

    $(document).on("mouseleave", "ul.users span", (e) => {
      if(this.timerActive || this.nodeSelected) { return false; }
      this.refreshData(this.arr, true);
    });
  }


  ///////////////////////
  // Private functions
  ///////////////////////


  csvToArray(str, delimiter = ",") {
    // slice from start of text to the first \n index
    // use split to create an array from string by delimiter
    const headers = str.slice(0, str.indexOf("\n")).split(delimiter);

    // slice from \n index + 1 to the end of the text
    // use split to create an array of each csv value row
    const rows = str.slice(str.indexOf("\n") + 1).split("\n");

    // Map the rows
    // split values from each row into an array
    // use headers.reduce to create an object
    // object properties derived from headers:values
    // the object passed as an element of the array
    const arr = rows.map((row) => {
      const values = row.split(delimiter);
      const el = headers.reduce((object, header, index) => {
        object[header] = values[index];
        return object;
      }, {});
      return el;
    });

    // return the array
    return arr;
  }

  getDates(arr) {
    return [...new Set(arr.map(i => i.timestamp))].map(i => new Date(i)).sort((a,b) => {
      return a - b;
    });
  }

  getUsers(arr) {
    let usersTotal = new Set();
    let usersWithActivity = new Set();
    let usersWithCount = {};
    arr.forEach(i => {
      if(i.item_type === "user"){
        usersTotal.add(i.item_id)
      } else if (i.user_id !== undefined && i.user_id !== null && i.user_id.toString().length > 0) {
        usersTotal.add(i.user_id)
        usersWithActivity.add(i.user_id)
      }
    });

    console.log(usersTotal.size, usersWithActivity.size, this.selectedRange);

    // // Truncate to 3000 nodes
    // if(usersTotal.size > 3000) {
    //   if(this.selectedRange === 'all') {
    //     usersWithCount = arr.reduce((sums,i) => {
    //       if(i.user_id !== undefined && i.user_id !== null && i.user_id.toString().length > 0) {
    //         const key = i.user_id
    //         if(!(key in sums)) { sums[key] = {count: 0, timestamp: i.timestamp, item_url: i.item_url } }
    //         sums[key].count++;
    //       }
    //       return sums;
    //     }, {});
    //   } else {
    //     const pendingSlots = 3000 - usersWithActivity.size;
    //     let pending = 0;
    //     usersWithCount = arr.reduce((sums,i) => {
    //       const key = i.item_id
    //       if(i.item_type === "user") {
    //         if(pending <= pendingSlots) {
    //           if(!(key in sums)) { sums[key] = {count: 0, timestamp: i.timestamp, item_url: i.item_url } }
    //           sums[key].count++;
    //           pending++;
    //         }
    //       } else if(i.user_id !== undefined && i.user_id !== null && i.user_id.toString().length > 0) {
    //         if(!(key in sums)) { sums[key] = {count: 0, timestamp: i.timestamp, item_url: i.item_url } }
    //         sums[key].count++;
    //       }
    //       return sums;
    //     }, {});
    //   }
    // } else {
    //   usersWithCount = arr.reduce((sums,i) => {
    //     const key = i.item_id
    //     if(i.item_type === "user") {
    //       if(!(key in sums)) { sums[key] = {count: 0, timestamp: i.timestamp, item_url: i.item_url } }
    //       sums[key].count++;
    //     } else if(i.user_id !== undefined && i.user_id !== null && i.user_id.toString().length > 0) {
    //       if(!(key in sums)) { sums[key] = {count: 0, timestamp: i.timestamp, item_url: i.item_url } }
    //       sums[key].count++;
    //     }
    //     return sums;
    //   }, {});
    // }

    usersWithCount = arr.reduce((sums,i) => {
      const key = i.user_id
      if(i.user_id !== undefined && i.user_id !== null && i.user_id.toString().length > 0) {
        if(!(key in sums)) { sums[key] = {count: 0, timestamp: i.timestamp, item_url: i.item_url } }
        sums[key].count++;
      }
      return sums;
    }, {});

    return this.mapToSortedArrayWithClass(usersWithCount, 10);
  }

  getContributions(arr) {
    const contributionsWithCount = arr.reduce((sums, i) => {
      if(i.item_type === "proposal" || i.item_type === "debate" || i.item_type === "meeting" || i.item_type === "initiative") {
        const key = `${i.item_type}_${i.item_id}`;
        if(!(key in sums)) { sums[key] = {count: 0, timestamp: i.timestamp, item_url: i.item_url} }
        sums[key].count++;
      }
      if(i.target_type === "proposal" || i.target_type === "debate" || i.target_type === "meeting" || i.target_type === "initiative") {
        const key = `${i.target_type}_${i.target_id}`;
        if(!(key in sums)) { sums[key] = {count: 0, timestamp: i.timestamp, item_url: i.item_url} }
        sums[key].count++;
      }
      return sums;
    }, {});

    return this.mapToSortedArrayWithClass(contributionsWithCount, 10);
  }

  mapToSortedArrayWithClass(itemsWithCount, totalClasses) {
    const totalItems = Object.keys(itemsWithCount).length;

    if(totalItems === 1) {
      const id = Object.keys(itemsWithCount)[0];
      return [{id: id, count: 1, group: 1, timestamp: itemsWithCount[id].timestamp, item_url: itemsWithCount[id].item_url}]
    }

    let result = [];
    let groups = {}
    for(let i=1;i<=totalClasses;i++){
      groups[i] = [];
    }

    const minValue = 0;
    const maxValue = max(Object.values(itemsWithCount).map(v => Math.log(v.count)));
    let bin = maxValue/(totalClasses - 1);
    // When maxValue is 0
    if(bin === 0) { bin = 1; }

    Object.keys(itemsWithCount).forEach(id => {
      const count = itemsWithCount[id].count;
      if(count !== undefined) {
        let group = Math.floor(Math.log(count)/bin) + 1;
        groups[group].push(id);
      }
    });

    Object.entries(groups).forEach(([group, ids]) => {
      ids.forEach((id) => {
        if(!this.contains(result, id)) {
          result.push({ id: id, count: itemsWithCount[id].count, group: group, timestamp: itemsWithCount[id].timestamp, item_url: itemsWithCount[id].item_url });
        }
      })
    });

    return result.sort((a,b) => {
      return new Date(a.timestamp) - new Date(b.timestamp)
    });
  }

  contains(arr, id) {
    let i = arr.length;
    if(i === 0) { return false; }

    while (i--) {
      if (arr[i].id === id) {
        return true;
      }
    }
    return false;
  }

  updateComments(arr) {
    const data = arr.filter(i => i.item_type === 'comment');
    $('#interactions .comments').html(`${data.length} comments`);
  }

  updateVotes(arr) {
    const data = arr.filter(i => i.item_type !== undefined && i.item_type.indexOf('vote') > -1);
    $('#interactions .votes').html(`${data.length} votes`);
  }

  updateEndorsements(arr) {
    const data = arr.filter(i => i.item_type === 'endorsement');
    $('#interactions .supports').html(`${data.length} supports`);
  }

  updateFollowings(arr) {
    const data = arr.filter(i => i.item_type === 'following');
    $('#interactions .followings').html(`${data.length} followings`);
  }

  filterDataByDateRange(dateFrom, arr) {
    return arr.filter(i => new Date(i.timestamp) >= dateFrom);
  }

  filterDataByDate(date, arr) {
    let dateString = date.toISOString().split('T')[0];
    return arr.filter(i => i.timestamp === dateString);
  }

  renderHistogram(selector, rawData) {
    // set the dimensions and margins of the graph
    const margin = {top: 10, right: 30, bottom: 30, left: 40},
      width = 400 - margin.left - margin.right,
      height = 200 - margin.top - margin.bottom;

    const data = Object.values(rawData.reduce((sums,i) => {
      const key = i.timestamp
      if(!(key in sums)) { sums[key] = {value: 0, timestamp: new Date(i.timestamp)} }
      sums[key].value++;

      return sums;
    }, {}));

    // set the ranges
    const x = scaleTime()
      .domain(extent(data.map(d => d.timestamp)))
      .rangeRound([0, width]);
    const y = scaleLinear()
      .range([height, 0]);

    // set the parameters for the histogram
    const histogramInstance = histogram()
      .value(function(d) { return d.timestamp; })
      .domain(x.domain())
      .thresholds(x.ticks(timeMonth));


    // append the svg object to the body of the page
    // append a 'group' element to 'svg'
    // moves the 'group' element to the top left margin
    if($(`${selector} svg`).length) { $(`${selector} svg`).remove() }
    let svg = select(selector).append("svg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
      .append("g")
      .attr("transform",
        "translate(" + margin.left + "," + margin.top + ")");

    // group the data for the bars
    const bins = histogramInstance(data);

    // Scale the range of the data in the y domain
    y.domain([0, max(bins, function(d) { return d.length; })]);

    // append the bar rectangles to the svg element
    svg.selectAll("rect")
      .data(bins)
      .enter().append("rect")
      .attr("class", "bar")
      .attr("x", 1)
      .attr("transform", function(d) {
        return "translate(" + x(d.x0) + "," + y(d.length) + ")"; })
      .attr("width", function(d) { return x(d.x1) - x(d.x0) -1 ; })
      .attr("height", function(d) { return height - y(d.length); });

    // add the x Axis
    svg.append("g")
      .attr("transform", "translate(0," + height + ")")
      .call(axisBottom(x));

    // add the y Axis
    svg.append("g")
      .call(axisLeft(y));
  }

  refreshData(filteredData, useTotals = false) {
    this.resetActiveElements();

    // Render contributions
    let contributions = null;
    let totalContributions = null;
    if(useTotals) {
      if(this.cachedContributions === null) {
        this.cachedContributions = this.getContributions(filteredData);
      }
      if(this.cachedTotalContributions === null) {
        this.cachedTotalContributions = Object.keys(this.cachedContributions).length;
      }
      contributions = this.cachedContributions;
      totalContributions = this.cachedTotalContributions;
    } else {
      contributions = this.getContributions(filteredData);
      totalContributions = Object.keys(contributions).length;
    }

    if(useTotals) {
      $('#contributions h2 span.total').html(totalContributions);
      $('#contributions h2 span.partial').html('');
    } else {
      $('#contributions h2 span.partial').html(`${totalContributions} /`);
    }

    if($('ul.contributions').html().length === 0) {
      // Display contributions by timestamp
      contributions.forEach((contribution) => {
        const [itemType,itemId] = contribution.id.split('_')
        $('ul.contributions').append(`<li><span data-id="${itemId}" data-type="${itemType}" data-tippy-content="${itemType} - ${itemId}"></span></li>`);
      });
    }

    // Render users
    let users = null;
    let totalUsers = null;
    if(useTotals) {
      if(this.cachedUsers === null) {
        this.cachedUsers = this.getUsers(filteredData);
      }
      if(this.cachedTotalUsers === null) {
        this.cachedTotalUsers = Object.keys(this.cachedUsers).length;
      }
      users = this.cachedUsers;
      totalUsers = this.cachedTotalUsers;
    } else {
      users = this.getUsers(filteredData);
      totalUsers = Object.keys(users).length;
    }

    // Add count users
    if(useTotals) {
      $('#users h2 span.total').html(totalUsers);
      $('#users h2 span.partial').html('');
    } else {
      $('#users h2 span.partial').html(`${totalUsers} /`);
    }

    if($('ul.users').html().length === 0) {
      // Display users by timestamp
      users.forEach(user => {
        $('ul.users').append(`<li><span data-id="${user.id}" data-type="user" data-tippy-content="user - ${user.id}" class="tooltip"></span></li>`);
      })
    }

    this.updateComments(filteredData);
    this.updateVotes(filteredData);
    this.updateFollowings(filteredData);
    this.updateEndorsements(filteredData);

    users.forEach(user => {
      $(`.users span[data-id="${user.id}"]`).addClass(`active${user.group}`);
    })

    contributions.forEach(contribution => {
      const [itemType,itemId] = contribution.id.split('_')
      $(`.contributions span[data-id="${itemId}"][data-type="${itemType}"]`).addClass(`active${contribution.group}`);
    })

    this.renderHistogram("#users-histogram", users);
    this.renderHistogram("#contributions-histogram", contributions);
  }

  resetActiveElements() {
    for(let i=1;i<=10;i++) {
      $(`.users span.active${i}`).removeClass(`active${i}`);
      $(`.contributions span.active${i}`).removeClass(`active${i}`);
    }
  }
}
