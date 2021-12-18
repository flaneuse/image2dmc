<template>
<div class="m-5">
  <h1>Happy Christmas, Mom!</h1>

  <h3 class="text-left">Select an image to match to DMC embroidery floss colors</h3>

  <!-- select file & match button -->
  <div id="input-opts" class="d-flex flex-wrap mb-3 align-items-start justify-content-between">
    <!-- select file -->
    <div class="d-flex flex-column align-items-start">
      <span class="badge badge-pill badge-info m-0 fa-lg mb-2">1 Select file</span>
      <b-form-file type="file" id="file" accept="image/*" @change="loadFile"/>
    </div>

    <div class="d-flex flex-column align-items-start" v-if="fileLoaded">
      <span class="badge badge-pill badge-info m-0 fa-lg mb-2">2 Adjust simplification</span>
      <div class="d-flex align-items-start">
      <b-button @click="matchColors" class="btn-outline-secondary mr-3" :class="{'disabled': isMatching}">crop</b-button>
      <!-- change amount of averaging -->
      <div id="input-degree-avg mr-5 d-flex align-items-center">
        <label for="num-colors" class="d-flex justify-content-between mr-2 mb-n2">
          Amount of simplifcation
          <span v-if="numColors2Match">{{numColors2Match.toLocaleString()}} colors to match</span>
        </label>

        <b-form-input id="num-colors" v-model="rgbPrecision" type="range" min="1" max="100" step="1" @change="simplifyImage()"></b-form-input>
        <div class="d-flex justify-content-between mt-n2">
          <span>none</span>
          <span>max</span>
        </div>
        <div>
          Est. time: ~ {{estimatedTime}}
        </div>
      </div>
      </div>
    </div>


    <div v-if="fileLoaded" class="d-flex flex-column align-items-start">
      <span class="badge badge-pill badge-info m-0 fa-lg mb-2">3 Match colors</span>
      <div class="d-flex">
        <!-- execute -->
        <b-button @click="matchColors" class="btn btn-info btn-lg" :class="{'disabled': isMatching}">Match</b-button>

        <!-- Progress bar -->
        <div class="ml-3 w-400px">
          <div class="d-flex flex-column arrange-items-center">
            <small class="text-muted">Percent matched</small>
            <b-progress max="1" height="1.25rem" show-progress :animated="matchProgress < 1">
              <b-progress-bar :value="matchProgress" :label="`${(matchProgress * 100).toFixed(1)}%`" key="pb"></b-progress-bar>
            </b-progress>
          </div>
        </div>
      </div>
    </div>

  </div>



  <!-- image previews -->
  <div id="image-previews" class="d-flex flex-wrap">
    <div id="original-preview">
      <h5>original image</h5>
      <canvas id="canvas"></canvas>
    </div>

    <div id="average-preview" class="ml-2">
      <h5>simplified image</h5>
      <canvas id="preview"></canvas>

      <!-- change amount of averaging -->
      <div id="input-degree-avg mr-5 d-flex align-items-center">
        <label for="num-colors" class="d-flex justify-content-between mr-2 mb-n2">
          Amount of simplifcation
          <span v-if="numColors2Match">{{numColors2Match.toLocaleString()}} colors to match</span>
        </label>

        <b-form-input id="num-colors" v-model="rgbPrecision" type="range" min="1" max="100" step="1" @change="simplifyImage()"></b-form-input>
        <div class="d-flex justify-content-between mt-n2">
          <span>none</span>
          <span>max</span>
        </div>
        <div>
          Est. time: ~ {{estimatedTime}}
        </div>
      </div>
    </div>
  </div>


  <!-- results -->
  <div id="results" v-if="filteredMatches.length" class="border-top mt-4 pt-4 ">
    <h2>Matched colors</h2>
    <!-- number of colors -->
    <div class="d-flex justify-content-end">
      <div id="input-num-colors mr-5 d-flex align-items-center justify-content-end w-25">
        <label for="num-colors" class="flex-shrink-0 mr-2">Number of colors</label>
        <b-form-input id="num-colors" v-model="numMatches" type="number" min="1" placeholder="Number of colors"></b-form-input>
      </div>

    </div>


    <table>
      <thead>
        <tr class="font-weight-bold text-left">
          <td>

          </td>
          <td>
            DMC code
          </td>
          <td>
            name
          </td>
          <td>
            Percent of image
          </td>
          <td>
            Avg. score (lower is a closer match)
          </td>
        </tr>
      </thead>

      <tbody>
        <tr v-for="(color, idx) in filteredMatches" :key="idx" class="text-left">
          <td :style="{width: '50px', height: '25px', background: color.dmc_hex, border: '4px solid white'}">
          </td>
          <td>
            {{color.dmc_id}}
          </td>
          <td>
            {{color.dmc_name}}
          </td>
          <td>
            {{color.pct}}
          </td>
          <td>
            {{color.score}}
          </td>
        </tr>
      </tbody>

    </table>
  </div>

</div>
</template>

<script>
import {
  deltaE
} from "chroma-js";
import chroma from 'chroma-js';
import DMC from "@/assets/dmc_colors.json";
// import DMC from "@/assets/dmc_colors_ldh.json";
import chunk from "lodash/chunk";
import sumBy from "lodash/sumBy";
import countBy from "lodash/countBy";
import groupBy from "lodash/groupBy";
import * as _ from "lodash";
import * as d3 from "d3-format";

export default {
  name: 'ImportPic',
  data() {
    return {
      imageWidth: 80,
      imageHeight: 80,
      rgbPrecision: 5,
      matchProgress: 0,
      colorsPerSec: 570,
      numColors2Match: null,
      isMatching: false,
      fileLoaded: false,
      numMatches: 10,
      roundedRGBA: [],
      imageRaw: null,
      imagePixels: [],
      matchedColors: [],
      imageDMC: []
    }
  },
  computed: {
    filteredMatches() {
      return (this.matchedColors.slice(0, this.numMatches))
    },
    estimatedTime() {
      const est = this.numColors2Match / this.colorsPerSec;
      if (est < 0.05) {
        return ("< 0.1 seconds")
      } else if (est < 60) {
        return (`${d3.format("0.1f")(est)} seconds`)
      } else if (est < 3600) {
        return (`${d3.format("0.1f")(est/60)} minutes`)
      } else {
        return (`${d3.format("0.1f")(est/3600)} hours`)
      }
    }
  },
  watch: {
    roundedRGBA: function() {
      // plot rounded version
      if (this.roundedRGBA.length) {
        var canvas = document.getElementById('preview'); // load context of canvas
        canvas.width = this.imageWidth;
        canvas.height = this.imageHeight;
        var ctx = canvas.getContext('2d'); // load context of canvas
        var img = this.roundedRGBA.map(d => d.split(",")).flatMap(d => d).map((d, i) => (i + 1) % 4 === 0 ? 255 : +d);

        var palette = new ImageData(new Uint8ClampedArray(img), this.imageWidth, this.imageHeight)
        ctx.putImageData(palette, 0, 0);
      }
    }
  },
  mounted() {
    DMC.forEach(d => {
      // d["color"] = chroma(d.hex);
      d["color"] = chroma(`rgb(${d.r}, ${d.g}, ${d.b})`);
      d["hex"] = d.color.hex();
    })
  },
  methods: {
    loadFile(event) {
      // resetting the values on new file load.
      this.isMatching = false;
      this.matchProgress = 0;
      this.matchedColors = [];
      this.fileLoaded = false;

      var canvas = document.getElementById('canvas'); // load context of canvas
      var ctx = canvas.getContext('2d'); // load context of canvas
      var img = new Image();
      img.src = URL.createObjectURL(event.target.files[0]); // use first selected image from input element

      img.onload = (e) => {
        this.imageWidth = img.width * 0.5;
        this.imageHeight = img.height * 0.5;
        canvas.width = this.imageWidth;
        canvas.height = this.imageHeight;

        ctx.drawImage(img, 0, 0, this.imageWidth, this.imageHeight); // draw the image to the canvas
        this.imageRaw = ctx.getImageData(0, 0, this.imageWidth, this.imageHeight);

        this.simplifyImage();

        console.log(this.imagePixels.length)

        // allow color matching to happen
        this.fileLoaded = true;
      }
    },
    roundRGBA(arr) {
      return (`${this.round(arr[0])},${this.round(arr[1])},${this.round(arr[2])},${this.round(arr[3])/255}`)
    },
    round(value) {
      return Math.ceil(value / this.rgbPrecision) * this.rgbPrecision;
    },
    calcDist(color) {
      DMC.forEach(d => {
        d.dist = deltaE(color, d.color);
      })

      DMC.sort((a, b) => a.dist - b.dist);

      const closestColor = DMC[0];
      return (closestColor)
    },
    simplifyImage() {
      // split into RGBA values
      let pixels = chunk(this.imageRaw.data, 4);

      // round the RGB values to the nearest 5 units, to reduce the number of duplicate calculations to make.
      this.roundedRGBA = pixels.map(d => this.roundRGBA(d));

      // count the number of occurrences of RGBA values, to reduce to single values to compare.
      let chunkCount = countBy(this.roundedRGBA);

      // convert from an object to an array
      this.imagePixels = Object.keys(chunkCount).map(key => ({
        id: key,
        count: chunkCount[key]
      }));

      this.numColors2Match = this.imagePixels.length;


      // sort high to low
      this.imagePixels.sort((a, b) => b.count - a.count);
    },
    calcMatch(d, i) {
      return new Promise((resolve, reject) => {
        setTimeout(() => {
          this.matchProgress = (i + 1) / this.imagePixels.length;
          let obj = {};
          const rgba = d.id.split(",")
          obj["color"] = chroma(`rgba(${rgba[0]}, ${rgba[1]}, ${rgba[2]}, ${rgba[3]/255})`);
          const closest = this.calcDist(obj.color);
          obj["hex"] = obj.color.hex();
          obj["pixel_count"] = d.count;
          obj["closest_hex"] = closest.hex;
          obj["closest_name"] = closest.name;
          obj["closest_dmc_id"] = closest.dmc_id;
          obj["closest_score"] = closest.dist;
          resolve(obj)
        }, 0)
      });
    },
    matchColors() {
      this.isMatching = true;

      Promise.all(this.imagePixels.map((d, i) => this.calcMatch(d, i))).then((values) => {
        this.imageDMC = values;
        // sum number of occurrences of the DMC color
        this.matchedColors = _(this.imageDMC).groupBy("closest_dmc_id")
          .map((values, i) => ({
            values: values,
            dmc_id: values[0]["closest_dmc_id"],
            dmc_name: values[0]["closest_name"],
            dmc_hex: values[0]["closest_hex"],
            count: sumBy(values, "pixel_count"),
            score: d3.format("0.2f")(_.meanBy(values, "closest_score")),
            pct: d3.format("0.1%")(sumBy(values, "pixel_count") / this.roundedRGBA.length)
          }))
          .value()

        // sort descendingly by count
        this.matchedColors.sort((a, b) => b.count - a.count);
        this.isMatching = false;
      });
    }
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped lang="scss">
td {
    padding: 0.25rem 0.5rem;
}

.input-num-colors {
    width: 225px;
}

.disabled {
    pointer-events: none;
}

.w-400px {
    width: 400px;
}

.fa-lg {
    font-size: 1rem;
}

.btn-outline-secondary {
  background: none !important;
  &:hover{
    background: #aaa !important;
  }
}
</style>
