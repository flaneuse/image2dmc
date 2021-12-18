<template>
<div class="m-3 m-md-5" ref="container">
  <h1 class="my-5">Happy Christmas, Mom!</h1>

  <h3 class="text-left">Select an image to match to DMC embroidery floss colors</h3>

  <!-- select file & match button -->
  <div id="input-opts" class="d-flex flex-wrap mb-3 align-items-start justify-content-between">
    <!-- select file -->
    <div class="d-flex flex-column align-items-start my-2">
      <span class="badge badge-pill badge-secondary m-0 fa-lg mb-2">1 Select file</span>
      <b-form-file type="file" id="file" accept="image/*" @change="loadFile" />
    </div>

<!-- averaging -->
    <div class="d-flex flex-column align-items-start my-2" v-if="fileLoaded">
      <span class="badge badge-pill badge-secondary m-0 fa-lg mb-2">2 Adjust simplification</span>
      <div class="d-flex align-items-start">
        <b-button @click="matchColors" class="btn-outline-secondary mr-3" :class="{'disabled': isMatching}">crop</b-button>
        <!-- change amount of averaging -->
        <div id="input-degree-avg mr-5 d-flex align-items-center">
          <label for="num-colors" class="d-flex justify-content-between mr-2 mb-n2">
            Amount of simplifcation
          </label>

          <b-form-input id="num-colors" v-model="rgbPrecision" type="range" min="1" max="100" step="1" @change="simplifyImage()"></b-form-input>
          <div class="d-flex justify-content-between mt-n2">
            <span>none</span>
            <span>max</span>
          </div>
          <div class="d-flex justify-content-between">
            <span v-if="numColors2Match">{{numColors2Match.toLocaleString()}} colors to match</span>
            <span class="text-muted mx-2">&bull;</span>
            Est. time: ~ {{estimatedTime}}
          </div>
        </div>
      </div>
    </div>

<!-- match button w/ progress bar -->
    <div v-if="fileLoaded" class="d-flex flex-column align-items-start my-2">
      <span class="badge badge-pill badge-secondary m-0 fa-lg mb-2">3 Match colors</span>
      <div class="d-flex flex-wrap">
        <!-- execute -->
        <b-button @click="matchColors" class="btn btn-info btn-lg" :class="{'disabled': isMatching}">Match</b-button>

        <!-- Progress bar -->
        <div class="ml-3 w-400px">
          <div class="d-flex flex-column arrange-items-center">
            <small class="text-muted">Percent matched</small>
            <b-progress max="1" height="1.25rem" show-progress variant="info" :animated="matchProgress < 1">
              <b-progress-bar :value="matchProgress" :label="`${(matchProgress * 100).toFixed(1)}%`" key="pb"></b-progress-bar>
            </b-progress>
          </div>
        </div>
      </div>
    </div>

  </div>



  <!-- image previews -->
  <div id="image-previews" :class="[fileLoaded ? 'd-flex flex-column' : 'd-none' ]">
    <h3>Previews</h3>
    <div class="d-flex flex-wrap">

    <div id="original-preview">
      <h5>original image</h5>
      <canvas id="canvas"></canvas>
    </div>

    <div id="average-preview" class="ml-2">
      <h5>simplified image</h5>
      <canvas id="preview"></canvas>

      <!-- change amount of averaging -->
      <div id="input-degree-avg" class="mr-5 d-none d-md-flex align-items-center">
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
  </div>


  <!-- results -->
  <div id="results" class="border-top mt-4 pt-4 ">
    <div class="d-flex align-items-center mb-4" v-if="filteredMatches.length">
      <div class="d-flex flex-column align-items-start">
      <h2>Matched colors</h2>
      <a href="#matched-table">
        view table
      </a>
      </div>

      <!-- number of colors -->
      <div class="ml-5 d-flex justify-content-end">
        <div id="input-num-colors mr-5 text-left d-flex w-25">
          <label for="num-colors" class="flex-shrink-0 mr-2 m-0">Number of colors</label>
          <b-form-input id="num-colors" v-model="numMatches" type="number" min="1" placeholder="Number of colors"></b-form-input>
        </div>
      </div>
    </div>

    <div class="d-flex flex-wrap" id="preview-results">
      <div v-for="(result, rIdx) in numMatches" :key=rIdx class="m-2" :class="[filteredMatches.length ? 'd-flex flex-column align-items-start' : 'd-none' ]">
        <div class="d-flex" v-if="filteredMatches.length && filteredMatches[rIdx]">
          <div :style="{width: '50px', height: '25px', background: filteredMatches[rIdx].dmc_hex}">
          </div>
          <h4 class="m-0 ml-2"><span class="font-weight-bold">DMC {{filteredMatches[rIdx]["dmc_id"]}}</span> {{filteredMatches[rIdx]["dmc_name"]}}</h4>
        </div>
        <canvas :id="'result' + rIdx"></canvas>
      </div>
    </div>

    <template v-if="filteredMatches.length">
      <table id="matched-table">
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
            <td class="h4">
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
    </template>

  </div>

</div>
</template>

<script>
import {
  deltaE
} from "chroma-js";
import chroma from 'chroma-js';
// import DMC from "@/assets/dmc_colors.json";
import DMC from "@/assets/dmc_colors_ldh.json";
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
      maxWidth: 80,
      rgbPrecision: 5,
      matchProgress: 0,
      colorsPerSec: 500,
      numColors2Match: null,
      isMatching: false,
      fileLoaded: false,
      numMatches: 20,
      simplifiedImage: [],
      originalImage: null,
      simplifiedColorArr: [],
      matchedColors: [],
      matchedColorArr: [],
      matchedColorSmMult: []
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
    simplifiedImage: function() {
      // plot rounded version
      if (this.simplifiedImage.length) {
        var canvas = document.getElementById('preview'); // load context of canvas
        if(this.maxWidth > 500) {
          canvas.width = this.maxWidth * 0.45;
        } else {
          canvas.width = this.maxWidth * 0.95;
        }
        canvas.height = this.imageWidth * (this.imageHeight/this.imageWidth);

        var ctx = canvas.getContext('2d'); // load context of canvas
        var img = this.simplifiedImage.map(d => d.rgba.split(",")).flatMap(d => d).map((d, i) => (i + 1) % 4 === 0 ? 255 : +d);

        var palette = new ImageData(new Uint8ClampedArray(img), this.imageWidth, this.imageHeight)
        ctx.putImageData(palette, 0, 0);
      }
    },
    matchedColorSmMult: function() {
      // plot rounded version
      if (this.matchedColorSmMult.length) {
        this.matchedColorSmMult.forEach((d, i) => {
          if (i < this.numMatches) {
            this.plotResult(d, `result${i}`)
          }
        })
      }
    }
  },
  mounted() {
    this.maxWidth = this.$refs.container.clientWidth;
    DMC.forEach(d => {
      // d["color"] = chroma(`rgb(${d.r}, ${d.g}, ${d.b})`);
      // d["hex"] = d.color.hex();
      d["color"] = chroma(d.hex);
      d["rgb"] = d.color.rgb();
    })
  },
  methods: {
    plotResult(pixels, id) {
      var canvas = document.getElementById(id); // load context of canvas
      if(this.maxWidth > 1000) {
        canvas.width = this.maxWidth * 0.25;
      } else if(this.maxWidth > 500) {
        canvas.width = this.maxWidth * 0.45;
      } else {
        canvas.width = this.maxWidth * 0.95;
      }
      canvas.height = this.imageWidth * (this.imageHeight/this.imageWidth);

      var ctx = canvas.getContext('2d'); // load context of canvas
      var img = pixels;

      var palette = new ImageData(new Uint8ClampedArray(img), this.imageWidth, this.imageHeight)
      ctx.putImageData(palette, 0, 0);
    },
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
        if(this.maxWidth > 500) {
          this.imageWidth = this.maxWidth * 0.45;
          this.imageHeight = this.imageWidth * (img.height/img.width);
        } else {
          this.imageWidth = this.maxWidth * 0.95;
          this.imageHeight = this.imageWidth * (img.height/img.width);
        }

        canvas.width = this.imageWidth;
        canvas.height = this.imageHeight;

        ctx.drawImage(img, 0, 0, this.imageWidth, this.imageHeight); // draw the image to the canvas
        this.originalImage = ctx.getImageData(0, 0, this.imageWidth, this.imageHeight);

        this.simplifyImage();

        // allow color matching to happen
        this.fileLoaded = true;
      }
    },
    roundRGBA(arr, idx) {
      return ({
        idx: idx,
        rgba: `${this.round(arr[0])},${this.round(arr[1])},${this.round(arr[2])},${this.round(arr[3])/255}`
      })
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
      let pixels = chunk(this.originalImage.data, 4);

      // round the RGB values to the nearest 5 units, to reduce the number of duplicate calculations to make.
      this.simplifiedImage = pixels.map((d, i) => this.roundRGBA(d, i));

      // count the number of occurrences of RGBA values, to reduce to single values to compare.
      this.simplifiedColorArr = _(this.simplifiedImage).groupBy("rgba")
        .map((values, key) => ({
          idx: values.map(d => d.idx),
          count: values.length,
          id: key
        }))
        .value()

      this.numColors2Match = this.simplifiedColorArr.length;


      // sort high to low
      this.simplifiedColorArr.sort((a, b) => b.count - a.count);
    },
    calcMatch(d, i) {
      return new Promise((resolve, reject) => {
        setTimeout(() => {
          this.matchProgress = (i + 1) / this.simplifiedColorArr.length;
          let obj = {};
          const rgba = d.id.split(",")
          obj["color"] = chroma(`rgba(${rgba[0]}, ${rgba[1]}, ${rgba[2]}, ${rgba[3]/255})`);
          const closest = this.calcDist(obj.color);
          obj["hex"] = obj.color.hex();
          obj["idx"] = d.idx;
          obj["pixel_count"] = d.count;
          obj["closest_hex"] = closest.hex;
          obj["closest_rgb"] = closest.rgb;
          // obj["closest_rgb"] = [closest.r, closest.g, closest.b];
          obj["closest_name"] = closest.name;
          obj["closest_dmc_id"] = closest.dmc_id;
          obj["closest_score"] = closest.dist;
          resolve(obj)
        }, 0)
      });
    },
    matchColors() {
      this.isMatching = true;

      Promise.all(this.simplifiedColorArr.map((d, i) => this.calcMatch(d, i))).then((values) => {
        this.matchedColorArr = values;
        // sum number of occurrences of the DMC color
        this.matchedColors = _(this.matchedColorArr).groupBy("closest_dmc_id")
          .map((values, i) => ({
            values: values,
            dmc_id: values[0]["closest_dmc_id"],
            dmc_name: values[0]["closest_name"],
            dmc_hex: values[0]["closest_hex"],
            dmc_rgb: values[0]["closest_rgb"],
            idx: values.flatMap(d => d.idx),
            count: sumBy(values, "pixel_count"),
            score: d3.format("0.2f")(_.meanBy(values, "closest_score")),
            pct: d3.format("0.1%")(sumBy(values, "pixel_count") / this.simplifiedImage.length)
          }))
          .value();

        // sort descendingly by count
        this.matchedColors.sort((a, b) => b.count - a.count);

        // result small multiples
        this.matchedColorSmMult = this.matchedColors.map(color => {
          let pixels = new Array(this.simplifiedImage.length * 4).fill(0);
          color.idx.forEach(i => {
            pixels[+i * 4] = color.dmc_rgb[0];
            pixels[+i * 4 + 1] = color.dmc_rgb[1];
            pixels[+i * 4 + 2] = color.dmc_rgb[2];
            pixels[+i * 4 + 3] = 255;
          })
          return (pixels);
        })

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

@media (max-width: 420px) {
  .w-400px {
      width: 200px;
  }
}


.fa-lg {
    font-size: 1rem;
}

.btn-outline-secondary {
    background: none !important;
    &:hover {
        background: #aaa !important;
    }
}

canvas {
    border: 1px solid #555;
}
</style>
